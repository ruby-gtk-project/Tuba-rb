#!/usr/bin/env ruby
# frozen_string_literal: true

# Drives the ported view shell headlessly and asserts what it built.
#
#   nix develop --command xvfb-run -a ruby test/drive_shell.rb
#
# Everything here runs inside a real GtkApplication activation, because the
# Adwaita widgets the views are made of need a display and a style manager.

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'tmpdir'
require 'tuba'
require 'content_base_view'
require 'tabbed_base_view'
require 'shortcuts_window'
require 'profile_menu'
require 'settings'
require 'style'

FAILURES = []

def check(what)
  if yield
    puts "ok   #{what}"
  else
    FAILURES << what
    puts "FAIL #{what}"
  end
end

# A model object of the kind ContentBaseView's store holds: a GLib::Object
# that knows how to turn itself into a row.
class Post < GLib::Object
  include Widgetizable

  type_register

  def initialize(body)
    super()
    @body = body
  end

  def to_widget
    ListBoxRowWrapper.new.tap { |row| row.child = Gtk::Label.new(@body) }
  end
end

def drive_settings
  Dir.mktmpdir do |dir|
    path = File.join(dir, 'settings.json')
    settings = Settings.new(path: path)

    check('settings: defaults come from the schema') { settings.timeline_page_size == 20 }
    check('settings: boolean predicate') { settings.live_updates? && !settings.show_spoilers? }
    check('settings: color scheme maps to Adwaita') { settings.adwaita_color_scheme == :default }
    settings.color_scheme = 'dark'
    check('settings: color scheme follows the key') { settings.adwaita_color_scheme == :force_dark }

    settings.active_account = 'uuid-1'
    settings.default_post_visibility = 'unlisted'
    settings.active_account = 'uuid-2'
    check('settings: account keys are per account') { settings.default_post_visibility == 'public' }
    settings.active_account = 'uuid-1'
    check('settings: account keys come back') { settings.default_post_visibility == 'unlisted' }
    check('settings: persisted') { Settings.new(path: path).default_post_visibility == 'unlisted' }

    settings.forget_account('uuid-1')
    check('settings: forgetting an account drops its keys') { settings.default_post_visibility == 'public' }

    check('settings: debug values hide the sensitive keys') do
      settings.debug_values.keys.none? { |key| Settings::SENSITIVE_KEYS.include?(key) }
    end
    check('settings: debug values cover the rest') do
      settings.debug_values.length == Settings::DEFAULTS.length - Settings::SENSITIVE_KEYS.length
    end
  end
end

def drive_base_view
  ContentBaseView.new(label: 'Home', icon: 'tuba-user-home-symbolic').build.tap do |view|
    check('base: starts on the loading spinner') do
      view.states.visible_child_name == 'status' && view.status_stack.visible_child_name == 'spinner'
    end

    view.on_content_changed
    check('base: an empty model shows the empty state') do
      view.status_stack.visible_child_name == 'message' &&
        view.status_title_label.label == BaseView::STATUS_EMPTY &&
        view.status_image.visible?
    end

    view.on_error(404, 'Not Found')
    check('base: an error shows its reason and the reload button') do
      view.status_title_label.label == 'An Error Occurred' &&
        view.status_message_label.label == 'Not Found' &&
        view.status_image.icon_name == BaseView::ERROR_ICON &&
        view.status_button.visible? &&
        view.status_button.label == 'Reload'
    end

    check('base: wide views keep the large-view padding') { view.content_box.has_css_class?('large-view') }
    view.small = true
    check('base: narrow views drop it') { !view.content_box.has_css_class?('large-view') }
    view.small = false

    view.model.append(Post.new('first'))
    check('base: a filled model shows the content') { view.states.visible_child_name == 'content' }
    check('base: the row came from the model object') do
      view.content.get_row_at_index(0).child.label == 'first'
    end
    check('base: rows are cards') do
      view.content.get_row_at_index(0).has_css_class?('card') &&
        view.content.get_row_at_index(0).has_css_class?('card-spacing')
    end

    opened = []
    view.content.get_row_at_index(0).on_open { opened << true }
    view.on_content_item_activated(view.content.get_row_at_index(0))
    check('base: activating a row opens it') { opened.length == 1 }

    view.clear
    check('base: clearing empties the model') { view.model.n_items.zero? }
  end
end

def drive_tabbed_view
  TabbedBaseView.new(label: 'Explore').build.tap do |view|
    view.add_list_tab('Posts', 'tuba-chat-symbolic')
    view.add_list_tab('Hashtags', 'tuba-hashtag-symbolic', empty_state_title: 'No Hashtags')

    check('tabbed: both tabs are in the stack') { view.views.length == 2 }
    check('tabbed: the switcher drives the stack') { view.switcher.stack == view.stack }
    check('tabbed: the header starts on the switcher') { !view.title_stack_page_visible? }
    check('tabbed: tabs hide their own header') { !view.views.first.header.visible? }
    check('tabbed: an empty state title carries over') do
      view.views.last.empty_state_title == 'No Hashtags'
    end

    view.change_page_to_named('2')
    check('tabbed: switching follows the label') { view.label == 'Hashtags' }
    check('tabbed: the switched-to tab is current') { view.views.last.current? }

    view.activate_action('tabbedview.change-tab', GLib::Variant.new(1, 'i'))
    check('tabbed: Alt+1 goes back to the first tab') { view.stack.visible_child_name == '1' }

    view.views.first.label = 'Latest'
    check('tabbed: a tab renaming itself renames its page') do
      view.stack.get_page(view.views.first).title == 'Latest'
    end
  end
end

def drive_shortcuts_and_menu
  ShortcutsWindow.new.build.tap do |dialog|
    check('shortcuts: the dialog is titled') { dialog.title == 'Keyboard Shortcuts' }
    check('shortcuts: three sections') { ShortcutsWindow::SECTIONS.length == 3 }
  end

  ProfileMenu.new.build.tap do |menu|
    check('menu: the top level has the hinted section plus its items') do
      menu.n_items == 1 + ProfileMenu::PROFILE_ITEMS.length + 2
    end
  end
end

def drive_application
  Application.new.tap do |application|
    application.build
    application.app.signal_connect('activate') do
      GLib::Idle.add do
        check('app: the window holds the view shell') do
          application.window.child == application.root_view
        end
        check('app: the view knows its window') { application.root_view.window == application.window }
        check('app: the about dialog is built') do
          application.about_dialog.application_name == Application::NAME
        end
        check('app: the actions are installed') do
          %w[about shortcuts quit scroll-page-down scroll-page-up].all? do |name|
            application.app.has_action?(name)
          end
        end
        # GTK normalises what set_accels_for_action was given, so the
        # upstream spelling "<Ctrl>Q" comes back as "<Control>q".
        check('app: the accelerators are bound') do
          application.app.get_accels_for_action('app.quit') == ['<Control>q'] &&
            application.app.get_accels_for_action('app.scroll-page-up') == ['Page_Up']
        end
        application.app.quit
        GLib::Source::REMOVE
      end
    end
    application.run
  end
end

Style.apply
drive_settings
drive_base_view
drive_tabbed_view
drive_shortcuts_and_menu
drive_application

if FAILURES.empty?
  puts 'all checks passed'
else
  puts "#{FAILURES.length} failed: #{FAILURES.join(', ')}"
  exit 1
end
