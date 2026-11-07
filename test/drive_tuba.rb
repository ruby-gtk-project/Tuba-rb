# frozen_string_literal: true

# Drives the whole Tuba port headlessly: builds the real GtkApplication,
# fires its installed actions and accelerators, swaps the window's content
# through every view the port has (BaseView's loading/empty/error/content
# states, TabbedBaseView's tabs and switcher), opens every dialog and menu,
# and screenshots each state.
#
# Why this file exists: a port that parses cleanly and has never opened a
# window is not evidence of anything. The first run of this script is what
# found that TabbedBaseView#build silently failed to reparent its content
# (Adw.ToolbarView warned "assertion 'gtk_widget_get_parent (content) == NULL'
# failed" and left the old overlay in place) because `states` was still
# parented inside the base view's scrolled overlay when the swap ran.
#
# Run it from the repository root:
#
#   nix develop --command xvfb-run -a ruby test/drive_tuba.rb
#
# GTK4 has no offscreen backend on this machine - gtk_init fails outright with
# no display - so xvfb-run is not optional here.
#
# This script does not trust the ambient display's size. xvfb-run's own
# default virtual screen is 640x480, which clamps every toplevel's width to
# 640 regardless of what settings or set_default_size ask for, and silently
# puts every "wide" view into its narrow breakpoint - a run with that default
# screen deterministically fails "wide views keep the large-view padding"
# while reporting every other check green, which is a worse outcome than an
# honest failure. Rather than document a required `-s` flag that the standard
# `xvfb-run -a` invocation everywhere else in this repo omits (and that a
# forgotten flag then silently breaks), the block below re-execs itself under
# a nested Xvfb sized wide enough, the first time it runs. The outer display,
# whatever its size, is never touched; a second, independent X server is
# started on its own display number and handed to the real run.
unless ENV['TUBA_DRIVE_DISPLAY_SIZED']
  ENV['TUBA_DRIVE_DISPLAY_SIZED'] = '1'
  exec('xvfb-run', '-a', '-s', '-screen 0 1920x1080x24', 'ruby', __FILE__, *ARGV)
end

require 'fileutils'
require 'tmpdir'
require 'json'

# A scratch config directory, so a run never reads or writes the real one.
ENV['XDG_CONFIG_HOME'] = Dir.mktmpdir('tuba-drive')

# Upstream's own default (data/dev.geopjr.Tuba.gschema.xml: window-w 600)
# sits inside BaseView's 670px "small" breakpoint, so a freshly launched
# window is narrow by default - correct for upstream, but it means the
# desktop-sized states this drive script wants to see need a wider starting
# size than the default. `Settings#apply_to` reads this before the window is
# ever presented, which is the only point a toplevel's size can be changed
# reliably once GTK is managing it.
FileUtils.mkdir_p(File.join(ENV.fetch('XDG_CONFIG_HOME'), 'tuba-rb'))
File.write(
  File.join(ENV.fetch('XDG_CONFIG_HOME'), 'tuba-rb', 'settings.json'),
  JSON.generate({ 'window-w' => 900, 'window-h' => 700 }),
)

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'tuba'
require 'application'
require 'content_base_view'
require 'tabbed_base_view'
require 'shortcuts_window'
require 'profile_menu'
require 'composer'
require 'utils_exif'
require 'settings'
require 'style'
require 'vote_check_button'
require 'list_box_row_wrapper'
require 'widgetizable'
require 'avatar'
require_relative 'gtk_driver'

SHOTS = File.expand_path('../tmp/shots', __dir__)
FileUtils.rm_rf(SHOTS)

# A model object of the kind ContentBaseView's store holds: a GLib::Object
# that knows how to turn itself into a row, per Widgetizable.
class Post < GLib::Object
  include Widgetizable

  type_register

  attr_reader :body

  def initialize(body)
    super()
    @body = body
  end

  def to_widget
    ListBoxRowWrapper.new.tap { |row| row.child = Gtk::Label.new(@body) }
  end
end

# A model object that forgets to override #to_widget, to drive
# BasicWidgetizable's default.
class Forgetful < GLib::Object
  include Widgetizable

  type_register
end

GtkDriver.drive(Application.new, shots: SHOTS) do |d, app|
  d.window { app.window }

  base_view = nil
  tabbed_view = nil
  dialog_toplevel = nil

  d.step('app: the window holds the view shell') do
    d.check('the window child is the root view') { app.window.child == app.root_view }
    d.check('the view knows its window') { app.root_view.window == app.window }
    d.check('the actions are installed') do
      %w[about compose shortcuts quit scroll-page-down scroll-page-up].all? { |name| app.app.has_action?(name) }
    end
    # GTK normalises what set_accels_for_action was given, so the upstream
    # spelling "<Ctrl>Q" comes back as "<Control>q".
    d.check('the accelerators are bound') do
      app.app.get_accels_for_action('app.quit') == ['<Control>q'] &&
        app.app.get_accels_for_action('app.scroll-page-up') == ['Page_Up']
    end
    d.shot('01-main-window')
  end

  d.step('settings: persist and scope per account') do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'settings.json')
      settings = Settings.new(path: path)

      d.check('defaults come from the schema') { settings.timeline_page_size == 20 }
      d.check('boolean predicate') { settings.live_updates? && !settings.show_spoilers? }
      d.check('color scheme maps to Adwaita') { settings.adwaita_color_scheme == :default }
      settings.color_scheme = 'dark'
      d.check('color scheme follows the key') { settings.adwaita_color_scheme == :force_dark }

      settings.active_account = 'uuid-1'
      settings.default_post_visibility = 'unlisted'
      settings.active_account = 'uuid-2'
      d.check('account keys are per account') { settings.default_post_visibility == 'public' }
      settings.active_account = 'uuid-1'
      d.check('account keys come back') { settings.default_post_visibility == 'unlisted' }
      d.check('persisted across instances') { Settings.new(path: path).default_post_visibility == 'unlisted' }

      settings.forget_account('uuid-1')
      d.check('forgetting an account drops its keys') { settings.default_post_visibility == 'public' }

      d.check('debug values hide the sensitive keys') do
        settings.debug_values.keys.none? { |key| Settings::SENSITIVE_KEYS.include?(key) }
      end
    end
  end

  d.step('base view: attach a fresh view to the window') do
    base_view = ContentBaseView.new(label: 'Home', icon: 'tuba-user-home-symbolic').build
    app.window.child = base_view
  end

  # Screenshots need a settled frame: taking one in the same tick as the
  # mutation that produced the state (a stack switch, a model change) comes
  # back with "widget produced no render node", so every state change below
  # gets its own tick before anything shoots it.
  d.step('base view: starts on the loading spinner') do
    d.check('starts on the loading spinner (before content ever changes)') do
      base_view.states.visible_child_name == 'status' && base_view.status_stack.visible_child_name == 'spinner'
    end
    base_view.on_content_changed
  end

  d.step('base view: an empty model shows the empty state') do
    d.check('shows the empty state') do
      base_view.status_stack.visible_child_name == 'message' &&
        base_view.status_title_label.label == BaseView::STATUS_EMPTY &&
        base_view.status_image.visible?
    end
    d.shot('02-base-empty')
    base_view.on_error(404, 'Not Found')
  end

  d.step('base view: an error state shows its reason and a reload button') do
    d.check('shows the error title, message and icon') do
      base_view.status_title_label.label == 'An Error Occurred' &&
        base_view.status_message_label.label == 'Not Found' &&
        base_view.status_image.icon_name == BaseView::ERROR_ICON
    end
    d.check('shows the reload button') do
      base_view.status_button.visible? && base_view.status_button.label == 'Reload'
    end
    d.shot('03-base-error')
  end

  d.step('base view: wide vs. narrow padding') do
    d.check('wide views keep the large-view padding') { base_view.content_box.has_css_class?('large-view') }
    base_view.small = true
    d.check('narrow views drop it') { !base_view.content_box.has_css_class?('large-view') }
    base_view.small = false
  end

  d.step('base view: a filled model shows cards, and activating one opens it') do
    base_view.model.append(Post.new('first post'))
    base_view.model.append(Post.new('second post'))
    d.check('switches to the content page') { base_view.states.visible_child_name == 'content' }
    d.check('the row came from the model object') do
      base_view.content.get_row_at_index(0).child.label == 'first post'
    end
    d.check('rows are cards') do
      row = base_view.content.get_row_at_index(0)
      row.has_css_class?('card') && row.has_css_class?('card-spacing')
    end

    opened = []
    base_view.content.get_row_at_index(0).on_open { opened << true }
    base_view.content.get_row_at_index(0).activate
    d.check('activating a row opens it') { opened.length == 1 }
  end

  d.step('base view: content screenshot, then clearing empties the model') do
    d.shot('04-base-content')
    base_view.clear
    d.check('clearing empties the model') { base_view.model.n_items.zero? }
  end

  d.step('house widgets: VoteCheckButton and ListBoxRowWrapper') do
    check_button = VoteCheckButton.new
    d.check('vote check buttons centre themselves and tag their mode') do
      check_button.valign == :center && check_button.has_css_class?('selection-mode')
    end

    opened = []
    ListBoxRowWrapper.new.on_open { opened << true }.open
    d.check('a row wrapper notifies every subscriber it was opened') { opened.length == 1 }
  end

  d.step('house widgets: Avatar starts on initials, then follows an account') do
    avatar = Avatar.new
    d.check('a fresh avatar falls back to the default glyph') do
      avatar.custom_image.nil? && avatar.size == Avatar::DEFAULT_SIZE
    end
    d.check('it is a flat circular image button') do
      %w[flat circular image-button].all? { |klass| avatar.has_css_class?(klass) }
    end

    # No avatar: value kept untouched (nil), so #fetch_avatar is never
    # reached — this environment has no network, and the point of this
    # check is the no-avatar branch of #account=, not the HTTP fetch.
    account = Struct.new(:display_name, :avatar).new('Ada Lovelace', nil)
    avatar.account = account
    d.check('assigning an account is retained') { avatar.account == account }
    d.check('a nil avatar leaves the custom image unset') { avatar.custom_image.nil? }

    avatar.size = 32
    d.check('size is settable and readable') { avatar.size == 32 }
  end

  d.step('widgetizable: the defaults are loud, not silent') do
    d.check('a model with no #to_widget raises, naming itself') do
      begin
        Forgetful.new.to_widget
        false
      rescue RuntimeError => e
        e.message.include?('Forgetful') && e.message.include?('to_widget')
      end
    end
    d.check('a model with no #open warns instead of raising') do
      warning = nil
      original = Warning.method(:warn)
      begin
        Warning.define_singleton_method(:warn) { |message| warning = message }
        Forgetful.new.open
      ensure
        Warning.define_singleton_method(:warn, original)
      end
      !warning.nil? && warning.include?('Forgetful')
    end
  end

  d.step('tabbed view: build two tabs') do
    tabbed_view = TabbedBaseView.new(label: 'Explore').build
    tabbed_view.add_list_tab('Posts', 'tuba-chat-symbolic')
    tabbed_view.add_list_tab('Hashtags', 'tuba-hashtag-symbolic', empty_state_title: 'No Hashtags')
    app.window.child = tabbed_view
  end

  d.step('tabbed view: the stack replaced the scrolled page, not just visually') do
    d.check('both tabs are in the stack') { tabbed_view.views.length == 2 }
    d.check('the switcher drives the stack') { tabbed_view.switcher.stack == tabbed_view.stack }
    # The regression this harness exists to catch: Adw.ToolbarView#content=
    # asserts its new content has no parent, and `states` starts out parented
    # inside the base view's scrolled overlay. If that overlay is not cleared
    # first, the assertion fails, GTK logs a CRITICAL and silently leaves the
    # toolbar view showing the old overlay instead of the tab stack.
    d.check('the toolbar view really holds the state stack, not the old overlay') do
      tabbed_view.toolbar_view.content == tabbed_view.states
    end
    d.check('the header starts on the switcher') { !tabbed_view.title_stack_page_visible? }
    d.check('tabs hide their own header') { !tabbed_view.views.first.header.visible? }
    d.check('an empty state title carries over') { tabbed_view.views.last.empty_state_title == 'No Hashtags' }
    d.shot('05-tabbed-view')
  end

  d.step('tabbed view: switching tabs, and the Alt+1..9 shortcuts') do
    tabbed_view.change_page_to_named('2')
    d.check('switching follows the label') { tabbed_view.label == 'Hashtags' }
    d.check('the switched-to tab is current') { tabbed_view.views.last.current? }

    tabbed_view.activate_action('tabbedview.change-tab', GLib::Variant.new(1, 'i'))
    d.check('Alt+1 goes back to the first tab') { tabbed_view.stack.visible_child_name == '1' }

    tabbed_view.views.first.label = 'Latest'
    d.check('a tab renaming itself renames its page') do
      tabbed_view.stack.get_page(tabbed_view.views.first).title == 'Latest'
    end
  end

  # Opening and shooting share a tick split for the same reason the base view
  # states above do: a dialog's toplevel is not realised in the same tick it
  # is presented in, and shooting it immediately comes back with "widget
  # produced no render node".
  d.step('shortcuts dialog: opens from the app action with its three sections') do
    # Adw.ShortcutsDialog presented on a Gtk::ApplicationWindow (this port
    # cannot use Adwaita::ApplicationWindow - see the ruby-gtk skill) becomes
    # a plain Gtk::Window toplevel carrying the dialog's title, not an
    # instance of the dialog class itself.
    before = Gtk::Window.list_toplevels
    app.app.lookup_action('shortcuts').activate(nil)
    dialog_toplevel = (Gtk::Window.list_toplevels - before).first
    d.check('a new toplevel appeared') { !dialog_toplevel.nil? }
    d.check('it is titled for the shortcuts dialog') { dialog_toplevel&.title == 'Keyboard Shortcuts' }
    d.check('the dialog itself carries the same title') { ShortcutsWindow.new.build.title == 'Keyboard Shortcuts' }
    d.check('three sections') { ShortcutsWindow::SECTIONS.length == 3 }
  end

  d.step('shortcuts dialog: screenshot, then close it') do
    d.shot('06-shortcuts-dialog', dialog_toplevel)
    dialog_toplevel&.close
  end

  d.step('shortcuts dialog: closed cleanly') do
    d.check('no stray toplevel left behind') { Gtk::Window.list_toplevels.length == 1 }
  end

  d.step('about dialog: opens from the app action, populated') do
    before = Gtk::Window.list_toplevels
    app.app.lookup_action('about').activate(nil)
    dialog_toplevel = (Gtk::Window.list_toplevels - before).first
    d.check('a new toplevel appeared') { !dialog_toplevel.nil? }
    d.check('it is the about dialog, named and versioned') do
      app.about_dialog.application_name == Application::NAME && app.about_dialog.version == Application::VERSION
    end
  end

  d.step('about dialog: screenshot, then close it') do
    d.shot('07-about-dialog', dialog_toplevel)
    dialog_toplevel&.close
  end

  d.step('composer: opens from the app action, with spellcheck and an alt-text field') do
    before = Gtk::Window.list_toplevels
    app.app.lookup_action('compose').activate(nil)
    dialog_toplevel = (Gtk::Window.list_toplevels - before).first
    d.check('a new toplevel appeared') { !dialog_toplevel.nil? }
    d.check('it is titled for the composer') { dialog_toplevel&.title == 'New Post' }
  end

  d.step('composer: libspelling actually runs over what gets typed') do
    composer = Composer.new(settings: app.settings).tap(&:build)
    buffer = composer.instance_variable_get(:@buffer)
    tag = buffer.tag_table.lookup('misspelled')

    buffer.text = 'this sentnce has a typo'
    composer.send(:check_spelling)

    d.check('a misspelled word is tagged') do
      iter = buffer.get_iter_at(offset: buffer.text.index('sentnce'))
      iter.has_tag?(tag)
    end
    d.check('a correctly spelled word is not tagged') do
      iter = buffer.get_iter_at(offset: buffer.text.index('this'))
      !iter.has_tag?(tag)
    end

    composer.send(:window).destroy
  end

  d.step('composer: gexiv2 actually extracts alt text from a real file') do
    require 'gdk_pixbuf2'
    require 'tmpdir'

    Dir.mktmpdir do |dir|
      path = File.join(dir, 'attachment.png')
      GdkPixbuf::Pixbuf.new(colorspace: :rgb, has_alpha: false, bits_per_sample: 8, width: 2, height: 2).savev(path, 'png')

      metadata = GExiv2::Metadata.new
      metadata.open_path(path)
      metadata.set_tag_string('Xmp.dc.description', 'lang="x-default" A photo of a cat')
      metadata.save_file(path)

      d.check('Utils::Exif reads the embedded alt text back') do
        Utils::Exif.extract_alt_text(path) == 'A photo of a cat'
      end
      d.check('a file:// URI is handled the same way') do
        Utils::Exif.extract_alt_text("file://#{path}") == 'A photo of a cat'
      end

      composer = Composer.new(settings: app.settings).tap(&:build)
      composer.send(:on_image_chosen, path)
      d.check('the composer prefills the alt-text row from the image metadata') do
        composer.send(:alt_text_row).text == 'A photo of a cat'
      end

      composer.send(:window).destroy
    end
  end

  d.step('composer: screenshot, then close it') do
    d.shot('08-composer-dialog', dialog_toplevel)
    dialog_toplevel&.close
  end

  d.step('composer: closed cleanly') do
    d.check('no stray toplevel left behind') { Gtk::Window.list_toplevels.length == 1 }
  end

  d.step('profile menu: the hinted section plus every item') do
    menu = ProfileMenu.new.build
    d.check('the top level has the hinted section plus its items') do
      menu.n_items == 1 + ProfileMenu::PROFILE_ITEMS.length + 2
    end
  end

  d.step('app: the scroll-page actions do not blow up with no scrollable view') do
    app.window.child = app.root_view
    d.check('scroll-page-down fires without error') do
      app.app.lookup_action('scroll-page-down').activate(nil)
      true
    rescue StandardError
      false
    end
    d.check('scroll-page-up fires without error') do
      app.app.lookup_action('scroll-page-up').activate(nil)
      true
    rescue StandardError
      false
    end
  end
end
