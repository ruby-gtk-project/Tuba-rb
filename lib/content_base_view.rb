# frozen_string_literal: true

require 'adwaita'
require_relative 'base_view'
require_relative 'widgetizable'

# ContentBaseView is a BaseView whose content area is a list bound to a model:
# the base class of every timeline, every list of accounts and every thread.
#
# Ported from upstream's src/Views/ContentBase.vala. Upstream compiles either
# of two content widgets depending on its USE_LISTVIEW build flag; the port
# follows the default branch, the Gtk.ListBox one, which is what the shipped
# builds use and what the "fake-content" CSS class in data/style.css styles.
#
# Upstream's model is a GLib.ListStore of its Widgetizable interface. An
# interface GType cannot be named from Ruby, so the store holds GLib::Object
# and the objects in it include the Widgetizable mixin; #on_create_model_widget
# asks each one for its row exactly as upstream does.
#
class ContentBaseView < BaseView
  # Loading the next page starts once the viewport is within two page-heights
  # of the bottom, and cannot start again for a second.
  BOTTOM_REACHED_COOLDOWN = 1000
  CLOSE_TO_TOP = 100
  FOCUS_GRAB_DELAY = 500

  attr_reader :model

  def initialize(label: '', icon: nil)
    super
    @model = Gio::ListStore.new(GLib::Object)
    @bottom_reached_locked = false
  end

  def build
    super.tap do
      content_box.child = content

      content.tap do |list|
        list.bind_model(model) { |item| on_create_model_widget(item) }
        list.signal_connect('row-activated') { |_, row| on_content_item_activated(row) }
      end

      model.signal_connect('items-changed') { on_content_changed }
      scrolled.vadjustment.signal_connect('value-changed') { on_scrolled_vadjustment_value_change }
      scroll_to_top_rev.bind_property(
        'child-revealed',
        scroll_to_top_rev,
        'visible',
        :sync_create,
      )
    end
  end

  def empty? = model.n_items <= 0

  # Subscribes to the viewport coming back near the top of the list, which is
  # what upstream's `reached_close_to_top` signal reports; the notifications
  # view uses it to mark notifications read.
  def on_reached_close_to_top(&handler)
    tap { close_to_top_handlers << handler }
  end

  # An empty list shows the view's empty state; a list with something in it
  # shows the content, and takes focus if the empty state had it.
  def on_content_changed
    if empty?
      self.base_status = StatusMessage.new
    else
      unless base_status.nil?
        attempt_focus_grab
      end
      self.base_status = nil
    end
  end

  def clear
    super
    model.remove_all
  end

  # Drops everything but the first `count` rows — how a thread view keeps the
  # post it is about while reloading the replies around it.
  def clear_all_but_first(count = 1)
    @last_widget = nil
    self.base_status = nil
    if model.n_items > count
      model.splice(count, model.n_items - count, [])
    end
  end

  # Upstream's hook for fetching the next page. The base class only lifts the
  # lock again, so a view that does not paginate stops at the first page.
  def on_bottom_reached
    GLib::Timeout.add(BOTTOM_REACHED_COOLDOWN) do
      @bottom_reached_locked = false
      GLib::Source::REMOVE
    end
  end

  def on_create_model_widget(item)
    item.to_widget.tap do |widget|
      widget.add_css_class('card')
      widget.add_css_class('card-spacing')
      widget.focusable = true

      # Thread lines overflow slightly
      widget.overflow = :hidden
    end
  end

  def on_content_item_activated(row)
    if row.respond_to?(:open)
      row.open
    end
  end

  # Upstream clears the ListBox binding by hand when the view leaves the
  # navigation stack: Vala's closures keep a reference cycle alive otherwise,
  # and the same binding would keep every row's model object alive here.
  def unbind_listboxes
    content.bind_model(nil) { |item| on_create_model_widget(item) }
    @last_widget = nil
  end

  def content
    @content ||= Gtk::ListBox.new.tap do |list|
      list.selection_mode = :none
      list.add_css_class('fake-content')
      list.add_css_class('background')
    end
  end

  protected

    # Reveals the scroll-to-top button once the list has scrolled away from
    # the top and there is still somewhere to scroll to, and asks for the next
    # page when the bottom comes into range.
    def on_scrolled_vadjustment_value_change
      scrolled.vadjustment.then do |adjustment|
        if !@bottom_reached_locked && adjustment.value > adjustment.upper - adjustment.page_size * 2
          @bottom_reached_locked = true
          on_bottom_reached
        end

        (adjustment.value <= CLOSE_TO_TOP).then do |close_to_top|
          set_scroll_to_top_reveal_child(
            !close_to_top && adjustment.value + adjustment.page_size + CLOSE_TO_TOP < adjustment.upper,
          )

          if close_to_top
            close_to_top_handlers.each(&:call)
          end
        end
      end
    end

    def set_scroll_to_top_reveal_child(reveal)
      unless reveal == scroll_to_top_rev.reveal_child?
        if reveal
          scroll_to_top_rev.visible = true
        end
        scroll_to_top_rev.reveal_child = reveal
      end
    end

    # Fighting with NavigationView over focus: the first row only takes it
    # once the new page has actually been mapped.
    def attempt_focus_grab
      GLib::Timeout.add(FOCUS_GRAB_DELAY) do
        content.get_row_at_index(0).then do |row|
          if !row.nil? && row.mapped?
            row.grab_focus
          end
        end
        GLib::Source::REMOVE
      end
    end

  private

    def close_to_top_handlers = @close_to_top_handlers ||= []
end
