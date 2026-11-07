# frozen_string_literal: true

require 'adwaita'
require_relative 'base_view'
require_relative 'content_base_view'

# TabbedBaseView is a BaseView whose content is a stack of other views, shown
# through a view switcher in the header on a wide window and through a switcher
# bar at the bottom on a narrow one.
#
# Ported from upstream's src/Views/TabbedBase.vala. It reuses the base
# template's toolbar view and state stack: the scrolled content page is taken
# out and an Adw.ViewStack put in its place, so the tabs scroll themselves and
# the base view's own scrolled window and scroll-to-top button step aside.
#
# The header holds a Gtk.Stack with two pages, the switcher and a plain window
# title; the 550sp breakpoint swaps to the title and reveals the bottom
# switcher bar. Alt+1 to Alt+9 select a tab by position.
#
# I did not build add_timeline_tab or the Views.Accounts tab it would
# prefill, so the one tab type Tuba actually opens by default has no
# factory in this port, because I am an idiot who got the generic
# mechanism working and stopped before building the one real thing it
# was for.
# Upstream: src/Views/TabbedBase.vala#add_timeline_tab;
#           src/Views/Accounts.vala (unported).
# Port: only the generic #add_tab and #add_list_tab exist below.
#
class TabbedBaseView < BaseView
  SWITCHER_BREAKPOINT = 'max-width: 550sp'
  TAB_ACTION_GROUP = 'tabbedview'
  TAB_ACTION = 'change-tab'
  MAX_TAB_SHORTCUTS = 9

  attr_reader :views

  def initialize(label: '', icon: nil)
    super
    @id_counter = 0
    @views = []
    @last_view = nil
  end

  def build
    tap do
      super

      # The tabs bring their own scrolling, so the view stack replaces the
      # base view's scrolled page inside the state stack, and the state stack
      # becomes the toolbar view's content directly. `states` is still parented
      # inside the overlay BaseView#build put it in, and Adw.ToolbarView#content=
      # asserts its new content is unparented, so that has to be cleared first
      # or the reparent is silently refused (with a CRITICAL on stderr) and the
      # toolbar view is left showing the overlay instead.
      scrolled_overlay.child = nil
      toolbar_view.content = states
      states.remove(scrolled)
      states.add_named(stack, 'content')

      stack.signal_connect('notify::visible-child') { on_view_switched }

      switcher.stack = stack
      switcher_bar.stack = stack

      insert_action_group(TAB_ACTION_GROUP, tab_actions)
      add_controller(shortcut_controller)

      self.base_status = nil
    end
  end

  def change_page_to_named(name)
    stack.visible_child_name = name.to_s
  end

  # Adds a view as a tab, and keeps the page it lives on in step with the
  # view's own label, icon, badge and attention flag.
  def add_tab(view)
    @id_counter += 1
    views << view
    stack.add_titled(view, @id_counter.to_s, view.label).tap do |page|
      sync_page(page, view)
      view.on_change { |changed| sync_page(page, changed) }
      view.header.visible = false
    end
  end

  # Upstream's add_list_tab: a plain list tab whose rows come from whatever
  # the caller puts in its model.
  def add_list_tab(label, icon, empty_state_title: nil)
    ContentBaseView.new(label: label, icon: icon).tap do |tab|
      unless empty_state_title.nil?
        tab.empty_state_title = empty_state_title
      end
      tab.build
      add_tab(tab)
    end
  end

  def foreach_tab(&block)
    views.each(&block)
  end

  def clear
    foreach_tab(&:clear)
    on_content_changed
  end

  def on_content_changed
    foreach_tab(&:on_content_changed)
    self.base_status = nil
  end

  def scroll_page(up: false)
    stack.visible_child.then do |view|
      if view.is_a?(BaseView)
        view.scroll_page(up: up)
      end
    end
  end

  # Upstream's unbind_listboxes walks into every tab, because the tabs are the
  # ones holding the model bindings.
  def unbind_listboxes
    foreach_tab do |tab|
      if tab.respond_to?(:unbind_listboxes)
        tab.unbind_listboxes
      end
    end
    @last_widget = nil
  end

  # The header shows the switcher on a wide window and the view's title on a
  # narrow one.
  def build_header
    header.title_widget = title_stack

    title_stack.tap do |titles|
      titles.add_named(switcher, 'switcher')
      titles.add_named(title_widget, 'title')
    end

    toolbar_view.add_bottom_bar(switcher_bar)

    self.title_stack_page_visible = false
    self.small = true
    add_breakpoint(switcher_breakpoint)
  end

  def title_stack_page_visible? = title_stack.visible_child_name == 'title'

  def title_stack_page_visible=(value)
    if value
      title_stack.visible_child_name = 'title'
    else
      title_stack.visible_child_name = 'switcher'
    end
  end

  def stack = @stack ||= Adwaita::ViewStack.new.tap { |widget| widget.vexpand = true }

  def switcher
    @switcher ||= Adwaita::ViewSwitcher.new.tap { |widget| widget.policy = :wide }
  end

  def switcher_bar = @switcher_bar ||= Adwaita::ViewSwitcherBar.new

  def title_stack
    @title_stack ||= Gtk::Stack.new.tap { |widget| widget.hhomogeneous = false }
  end

  def switcher_breakpoint
    @switcher_breakpoint ||= Adwaita::Breakpoint.new(
      Adwaita::BreakpointCondition.parse(SWITCHER_BREAKPOINT),
    ).tap do |breakpoint|
      breakpoint.signal_connect('apply') do
        self.title_stack_page_visible = true
        switcher_bar.reveal = true
      end

      breakpoint.signal_connect('unapply') do
        self.title_stack_page_visible = false
        switcher_bar.reveal = false
      end
    end
  end

  def tab_actions
    @tab_actions ||= Gio::SimpleActionGroup.new.tap do |group|
      Gio::SimpleAction.new(TAB_ACTION, GLib::VariantType.new('i')).tap do |action|
        action.signal_connect('activate') { |_, parameter| change_tab_cb(parameter) }
        group.add_action(action)
      end
    end
  end

  # Alt+1 through Alt+9 pick a tab by position, which is the id add_tab gave
  # it. A trigger past the last tab does nothing.
  def shortcut_controller
    @shortcut_controller ||= Gtk::ShortcutController.new.tap do |controller|
      (1..MAX_TAB_SHORTCUTS).each do |position|
        controller.add_shortcut(tab_shortcut(position))
      end
    end
  end

  protected

    def change_tab_alt(id)
      stack.visible_child_name = id.to_s
    end

    # Upstream tracks the view it switched away from so it can tell it that it
    # is no longer current, which is what stops a hidden timeline streaming.
    def on_view_switched
      stack.visible_child.then do |view|
        unless @last_view.nil?
          @last_view.current = false
        end

        if view.is_a?(BaseView)
          self.label = view.label
          view.current = true
          @last_view = view
        end
      end
    end

  private

    def sync_page(page, view)
      page.icon_name = view.icon
      page.needs_attention = view.needs_attention
      page.badge_number = view.badge_number
      page.title = view.label
    end

  # The activate signal hands the action's "i" parameter over already
  # unwrapped, as a Ruby Integer, but a caller that invokes the action
  # directly may pass the GLib::Variant itself.
    def change_tab_cb(parameter)
      unless parameter.nil?
        tab_position(parameter).then do |page_id|
          if page_id <= @id_counter
            change_tab_alt(page_id)
          end
        end
      end
    end

    def tab_position(parameter)
      if parameter.is_a?(GLib::Variant)
        parameter.get_int32
      else
        parameter.to_i
      end
    end

    def tab_shortcut(position)
      Gtk::Shortcut.new(
        Gtk::KeyvalTrigger.new(Gdk::Keyval.const_get(:"KEY_#{position}"), :alt_mask),
        Gtk::NamedAction.new("#{TAB_ACTION_GROUP}.#{TAB_ACTION}"),
      ).tap do |shortcut|
        shortcut.arguments = GLib::Variant.new(position, 'i')
      end
    end
end
