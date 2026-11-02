# frozen_string_literal: true

require 'adwaita'

# BaseView is the shell every Tuba view sits in: a header bar, a scrolled
# content area clamped to a readable width, a scroll-to-top button that fades
# in once you have scrolled away from the top, and a status page that takes
# the content's place while loading, when there is nothing to show and when a
# request failed.
#
# Ported from upstream's src/Views/Base.vala and its template
# data/ui/views/base.ui. The widget tree, the CSS classes, the clamp sizes and
# the 670px breakpoint that drops the "large-view" class are the template's;
# the state machine around `base_status` is Base.vala's.
#
# Two deliberate differences from upstream:
#
# * Upstream reaches the application singleton for `is-mobile` and for the
#   main window (to install the view's action group and to read the focused
#   widget). Those are injected here instead — #mobile= and #window= — so a
#   view can be built and driven without a window.
# * Base.vala also mirrors its state into the accessibility tree with
#   gtk_accessible_update_state/update_property. The Ruby bindings cannot
#   marshal those calls' array-of-enum argument (GObjectIntrospection raises
#   on "GIArgument(array/C)[interface(enum)](GtkAccessibleState)"), so the
#   aria busy state and aria label are not set. Everything the sighted user
#   sees is unchanged.
#
class BaseView < Adwaita::BreakpointBin
  # translators: Fallback shown when there are 0 results
  STATUS_EMPTY = 'Nothing to see here'
  EMPTY_TIMELINE_ICON = 'tuba-background-app-ghost-symbolic'
  ERROR_ICON = 'tuba-sad-computer-symbolic'
  CLAMP_SIZE = 670
  SMALL_BREAKPOINT = 'max-width: 670px'

  # Upstream's Views.Base.StatusMessage: a title, a message, and whether the
  # spinner shows instead of them. A nil status means "show the content".
  StatusMessage = Struct.new(
    :title,
    :message,
    :loading,
    keyword_init: true,
  )

  attr_reader :label, :icon, :needs_attention, :badge_number, :last_widget, :base_status
  attr_accessor :is_main,
    :allow_nesting,
    :is_sidebar_item,
    :uid,
    :empty_state_title,
    :empty_timeline_icon,
    :window

  def initialize(label: '', icon: nil)
    super()
    @label = label
    @icon = icon
    @needs_attention = false
    @is_main = false
    @allow_nesting = false
    @is_sidebar_item = false
    @badge_number = 0
    @uid = -1
    @empty_state_title = STATUS_EMPTY
    @empty_timeline_icon = EMPTY_TIMELINE_ICON
    @small = false
    @show_back_button = true
    @mobile = false
    @current = false
    @last_widget = nil
    self.width_request = 360
    self.height_request = 200
    add_css_class('background')
  end

  def build
    tap do
      self.child = toolbar_view

      toolbar_view.tap do |view|
        view.add_top_bar(header)
        view.content = scrolled_overlay

        scrolled_overlay.tap do |overlay|
          overlay.add_overlay(scroll_to_top_rev)
          overlay.child = states

          scroll_to_top_rev.tap do |revealer|
            revealer.child = scroll_to_top

            scroll_to_top.signal_connect('clicked') { on_scroll_to_top }
          end

          states.tap do |stack|
            stack.add_named(status_scroller, 'status')
            stack.add_named(scrolled, 'content')

            status_scroller.tap do |scroller|
              scroller.child = status_viewport

              status_viewport.tap do |viewport|
                viewport.child = status_clamp

                status_clamp.tap do |clamp|
                  clamp.child = status_box

                  status_box.tap do |box|
                    box.append(status_image)
                    box.append(status_stack)
                    box.append(status_button)

                    status_stack.tap do |status|
                      status.add_named(status_message_box, 'message')
                      status.add_named(status_spinner, 'spinner')

                      status_message_box.tap do |message|
                        message.append(status_title_label)
                        message.append(status_message_label)
                      end
                    end
                  end
                end
              end
            end

            scrolled.tap { |scroller| scroller.child = content_box }
          end
        end
      end

      add_breakpoint(small_breakpoint)
      build_actions
      build_header

      # translators: button on the error state, retries the failed request
      status_button.label = 'Reload'
      self.base_status = StatusMessage.new(loading: true)
    end
  end

  # Upstream binds the label to the header's title, so assigning it updates
  # the header too.
  def label=(value)
    @label = value
    title_widget.title = value
    notify_change
  end

  def icon=(value)
    @icon = value
    notify_change
  end

  def needs_attention=(value)
    @needs_attention = value
    notify_change
  end

  def badge_number=(value)
    @badge_number = value
    notify_change
  end

  # Replaces upstream's bind_property calls from a view to the page that holds
  # it: a tabbed parent subscribes here so the ViewStackPage it made for this
  # view keeps following the view's label, icon, badge and attention flag.
  def on_change(&handler)
    tap { change_handlers << handler }
  end

  # Narrow windows drop the extra side padding "large-view" adds. Upstream
  # phrases it the other way round — the class is present exactly when the
  # view is not small — and the breakpoint below is what flips it.
  def small=(value)
    @small = value
    if value
      content_box.remove_css_class('large-view')
    else
      content_box.add_css_class('large-view')
    end
  end

  def small? = @small == true

  def show_back_button=(value)
    @show_back_button = value
    update_back_btn
  end

  def show_back_button? = @show_back_button == true

  # Replaces upstream's app.notify["is-mobile"] subscription: on a phone-sized
  # window every view shows a back button, not just the nested ones.
  def mobile=(value)
    @mobile = value
    update_back_btn
  end

  def mobile? = @mobile == true

  # Upstream's `current` property: becoming the visible view runs on_shown,
  # losing that runs on_hidden.
  def current=(value)
    @current = value
    if value
      on_shown
    else
      on_hidden
    end
  end

  def current? = @current == true

  # The state machine of the view: nil shows the content, a loading message
  # shows the spinner, and anything else shows the title/message page.
  def base_status=(value)
    status_image.visible = false
    status_image.icon_name = empty_timeline_icon
    status_button.visible = false

    if value.nil?
      show_state('content')
    else
      show_state('status')
      if value.loading
        show_status_page('spinner')
      else
        show_status_page('message')
        apply_status_message(value)
      end
    end

    @base_status = value
  end

  # Upstream's on_error: the sad-computer icon, the reason the request gave,
  # and a Reload button that the subclass's action answers.
  def on_error(_code, reason)
    self.base_status = StatusMessage.new(title: 'An Error Occurred', message: reason)
    status_image.icon_name = ERROR_ICON
    status_image.visible = true
    status_button.visible = true
    status_button.sensitive = true
  end

  def clear
    @last_widget = nil
    self.base_status = nil
  end

  def on_content_changed; end

  # Subclasses install their view actions here; the base view has none of its
  # own, which is also where upstream leaves it.
  def build_actions; end

  def build_header
    header.title_widget = title_widget
  end

  # A page of scrolling, for the app's Page_Up / Page_Down accelerators.
  def scroll_page(up: false)
    if up
      scrolled.scroll_child(:page_backward, false)
    else
      scrolled.scroll_child(:page_forward, false)
    end
  end

  # Remembers what had focus before a nested view was pushed, so popping back
  # can restore it. Upstream reads the focus off the main window.
  def update_last_widget(clear: false)
    if clear || window.nil?
      @last_widget = nil
    else
      @last_widget = window.focus
    end
  end

  # The view's own action group goes on the window under the "view" prefix,
  # which is the prefix every view-scoped menu item names.
  def on_shown
    unless window.nil?
      window.insert_action_group('view', actions)
    end
  end

  def on_hidden
    unless window.nil?
      window.insert_action_group('view', nil)
    end
  end

  def actions = @actions ||= Gio::SimpleActionGroup.new

  def toolbar_view
    @toolbar_view ||= Adwaita::ToolbarView.new.tap do |view|
      view.top_bar_style = :flat
      view.bottom_bar_style = :flat
    end
  end

  def header = @header ||= Adwaita::HeaderBar.new
  def title_widget = @title_widget ||= Adwaita::WindowTitle.new(label, '')
  def scrolled_overlay = @scrolled_overlay ||= Gtk::Overlay.new

  def scroll_to_top_rev
    @scroll_to_top_rev ||= Gtk::Revealer.new.tap do |revealer|
      revealer.transition_type = :crossfade
      revealer.reveal_child = false
      revealer.valign = :end
      revealer.halign = :end
      revealer.margin_end = 16
      revealer.margin_bottom = 16
      revealer.overflow = :visible
    end
  end

  def scroll_to_top
    @scroll_to_top ||= Gtk::Button.new.tap do |button|
      button.icon_name = 'go-top-symbolic'
      # translators: tooltip of the floating button that scrolls a timeline up
      button.tooltip_text = 'Scroll to Top'
      button.add_css_class('circular')
      button.add_css_class('osd')
    end
  end

  def states
    @states ||= Gtk::Stack.new.tap do |stack|
      stack.vexpand = true
      stack.vhomogeneous = false
      stack.transition_type = :crossfade
      stack.interpolate_size = true
    end
  end

  def status_scroller
    @status_scroller ||= Gtk::ScrolledWindow.new.tap do |scroller|
      scroller.vexpand = true
      scroller.hscrollbar_policy = :never
    end
  end

  def status_viewport = @status_viewport ||= Gtk::Viewport.new(nil, nil)
  def status_clamp = @status_clamp ||= clamp

  def status_box
    @status_box ||= Gtk::Box.new(:vertical, 16).tap do |box|
      box.valign = :center
      box.margin_top = 16
      box.margin_bottom = 16
    end
  end

  def status_image
    @status_image ||= Gtk::Image.new.tap do |image|
      image.width_request = 128
      image.height_request = 128
      image.pixel_size = 128
      image.icon_name = EMPTY_TIMELINE_ICON
      image.visible = false
      image.add_css_class('dim-label')
    end
  end

  def status_stack
    @status_stack ||= Gtk::Stack.new.tap { |stack| stack.transition_type = :crossfade }
  end

  def status_message_box
    @status_message_box ||= Gtk::Box.new(:vertical, 12).tap { |box| box.valign = :center }
  end

  def status_title_label
    @status_title_label ||= wrapping_label.tap do |label|
      label.add_css_class('title')
      label.add_css_class('title-1')
    end
  end

  def status_message_label
    @status_message_label ||= wrapping_label.tap do |label|
      label.add_css_class('body')
      label.add_css_class('description')
    end
  end

  def status_spinner
    @status_spinner ||= Adwaita::Spinner.new.tap do |spinner|
      spinner.height_request = 32
      spinner.valign = :center
    end
  end

  def status_button
    @status_button ||= Gtk::Button.new.tap do |button|
      button.visible = false
      button.halign = :center
      button.add_css_class('pill')
    end
  end

  def scrolled
    @scrolled ||= Gtk::ScrolledWindow.new.tap do |scroller|
      scroller.vexpand = true
      scroller.hscrollbar_policy = :never
    end
  end

  def content_box
    @content_box ||= clamp.tap do |box|
      box.add_css_class('ttl-view')
      box.add_css_class('large-view')
    end
  end

  def small_breakpoint
    @small_breakpoint ||= Adwaita::Breakpoint.new(
      Adwaita::BreakpointCondition.parse(SMALL_BREAKPOINT),
    ).tap do |breakpoint|
      breakpoint.signal_connect('apply') { self.small = true }
      breakpoint.signal_connect('unapply') { self.small = false }
    end
  end

  private

    def change_handlers = @change_handlers ||= []

    def notify_change
      change_handlers.each { |handler| handler.call(self) }
    end

    # Upstream's HACK, kept because the Adwaita bug it works around is still
    # open: show-back-button has no effect on its own, so the start title
    # buttons are toggled twice to force the header to re-layout.
    # https://gitlab.gnome.org/GNOME/libadwaita/-/issues/775
    def update_back_btn
      header.show_back_button = mobile? || show_back_button?
      header.show_start_title_buttons = !header.show_start_title_buttons?
      header.show_start_title_buttons = !header.show_start_title_buttons?
    end

    def on_scroll_to_top
      scrolled.scroll_child(:start, false)
    end

    def show_state(name)
      unless states.visible_child_name == name
        states.visible_child_name = name
      end
    end

    def show_status_page(name)
      unless status_stack.visible_child_name == name
        status_stack.visible_child_name = name
      end
    end

    # An empty status falls back to the view's own empty-state title and shows
    # the ghost icon with it; a titled one is a real message, like an error.
    def apply_status_message(value)
      if value.title.nil?
        status_title_label.label = empty_state_title
        status_image.visible = true
      else
        status_title_label.label = value.title
      end

      unless value.message.nil?
        status_message_label.label = value.message
      end
    end

    def clamp
      Adwaita::Clamp.new.tap do |widget|
        widget.vexpand = true
        widget.maximum_size = CLAMP_SIZE
        widget.tightening_threshold = CLAMP_SIZE
      end
    end

    def wrapping_label
      Gtk::Label.new.tap do |label|
        label.wrap = true
        label.wrap_mode = :word_char
        label.justify = :center
      end
    end
end
