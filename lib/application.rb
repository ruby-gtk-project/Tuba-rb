# frozen_string_literal: true

require 'adwaita'

require_relative 'settings'
require_relative 'utils_units'
require_relative 'utils_counting'
require_relative 'utils_date_time'
require_relative 'utils_tag_extractor'
require_relative 'style'
require_relative 'widgetizable'
require_relative 'list_box_row_wrapper'
require_relative 'vote_check_button'
require_relative 'avatar'
require_relative 'base_view'
require_relative 'content_base_view'
require_relative 'tabbed_base_view'
require_relative 'shortcuts_window'
require_relative 'profile_menu'
require_relative 'composer'
require_relative 'preferences_dialog'

# Application is Tuba's GtkApplication.
#
# Ported from upstream's src/Application.vala: the application id, the actions
# and accelerators it installs, the stylesheet and color scheme it applies at
# startup, and the about dialog.
#
# I did not build the real window - no sidebar, no account switcher, no
# split view - and quietly handed the app's root content area a generic
# test-stub view instead, because I am an idiot who built scaffolding and
# called it close enough to the real thing.
# Upstream: src/Dialogs/MainWindow.vala.
# Port: window.child below is a bare ContentBaseView, the same generic view
# upstream hands out from TabbedBase.add_list_tab, showing its empty state
# because nothing ever feeds it real data.
#
# I also did not build roughly a dozen of upstream's remaining app-level
# actions - refresh, search, new-window, account switching - because
# I am an idiot who wired up the actions that needed no network or account
# layer and stopped there. APP_ENTRIES upstream declares the full set; only
# about, compose, open-preferences, quit, the two page-scroll actions and
# the keyboard shortcuts dialog are installed below, with accelerators to
# match. Compose is wired to a real dialog (lib/composer.rb) rather than
# skipped, because it is the only reachable place for this port to actually
# call two gems
# (gexiv2, libspelling) its gemspec claimed as dependencies but nothing
# under lib/ ever invoked.
#
class Application
  APP_ID = 'dev.geopjr.TubaRb'
  NAME = 'Tuba'
  VERSION = '0.11.1'
  WEBSITE = 'https://codeberg.org/GeopJr/Tuba'
  WIKI_WEBSITE = 'https://codeberg.org/GeopJr/Tuba/wiki'
  DONATE_WEBSITE = 'https://geopjr.dev/donate'
  TRANSLATE_WEBSITE = 'https://translate.codeberg.org/engage/tuba/'
  COPYRIGHT = "© 2018-2022 bleak_grey\n© 2022 Evangelos “GeopJr” Paterakis"

  DEVELOPERS = [
    'Evangelos “GeopJr” Paterakis',
    'bleak_grey',
    'Sergey Bugaev',
  ].freeze

  ARTISTS = [
    'Tobias Bernard',
    'Jakub Steiner',
  ].freeze

  DESIGNERS = [
    'Tobias Bernard',
    'Brage Fuglseth',
  ].freeze

  # Upstream's set_accels_for_action calls, for the actions this port has.
  ACCELS = {
    'app.about'            => ['F1'],
    'app.compose'          => ['<Ctrl>T', '<Ctrl>N'],
    'app.open-preferences' => ['<Ctrl>comma'],
    'app.quit'             => ['<Ctrl>Q'],
    'window.close'         => ['<Ctrl>W'],
    'app.scroll-page-down' => ['Page_Down'],
    'app.scroll-page-up'   => ['Page_Up'],
  }.freeze

  # The apps upstream's about dialog points at, as [id, name, summary].
  OTHER_APPS = [
    # translators: Application metainfo for the app "Archives"
    ['dev.geopjr.Archives', 'Archives', 'Create and view web archives'],
    # translators: Application metainfo for the app "Calligraphy"
    ['dev.geopjr.Calligraphy', 'Calligraphy', 'Turn text into ASCII banners'],
    # translators: Application metainfo for the app "Collision"
    ['dev.geopjr.Collision', 'Collision', 'Check hashes for your files'],
    # translators: Application metainfo for the app "Turntable"
    ['dev.geopjr.Turntable', 'Turntable', 'Scrobble your music'],
  ].freeze

  def build
    app.tap do
      app.signal_connect('startup') do
        Style.apply
        Adwaita::StyleManager.default.color_scheme = settings.adwaita_color_scheme
        install_actions
      end

      app.signal_connect('activate') do
        window.tap do |win|
          win.child = root_view

          win.signal_connect('close-request') do
            settings.remember(win)
            false
          end
        end

        root_view.tap do |view|
          view.window = window
          view.build
          view.on_content_changed
          view.current = true
        end

        window.present
      end
    end
  end

  def run = app.run([])

  def settings = @settings ||= Settings.new

  # Adwaita::Application is broken in the Ruby bindings; the application
  # object comes from Gtk and only the widgets inside it are Adwaita.
  def app = @app ||= Gtk::Application.new(APP_ID, :default_flags)

  def window
    @window ||= Gtk::ApplicationWindow.new(app).tap do |win|
      win.title = NAME
      win.icon_name = APP_ID
      win.resizable = true
      settings.apply_to(win)
    end
  end

  def root_view = @root_view ||= ContentBaseView.new(label: NAME)

  # Upstream's about_activated. Upstream builds the dialog from its installed
  # appdata; without a GResource bundle the same fields are set directly.
  def about_dialog
    Adwaita::AboutDialog.new.tap do |dialog|
      dialog.application_name = NAME
      dialog.application_icon = APP_ID
      dialog.version = VERSION
      dialog.website = WEBSITE
      dialog.issue_url = "#{WEBSITE}/issues"
      dialog.copyright = COPYRIGHT
      dialog.developers = DEVELOPERS
      dialog.artists = ARTISTS
      dialog.designers = DESIGNERS
      # translators: Name <email@domain.com> or Name https://website.example
      dialog.translator_credits = 'translator-credits'
      # translators: Wiki pages / Guides
      dialog.add_link('Wiki', WIKI_WEBSITE)
      dialog.add_link('Translate', TRANSLATE_WEBSITE)
      dialog.add_link('Donate', DONATE_WEBSITE)
      OTHER_APPS.each { |id, name, summary| dialog.add_other_app(id, name, summary) }
    end
  end

  def shortcuts_window = ShortcutsWindow.new.build

  def composer = Composer.new(settings: settings).tap { |c| c.build }

  def preferences_dialog = PreferencesDialog.new(settings: settings).tap { |d| d.build }

  private

    def install_actions
      action('about') { about_dialog.present(window) }
      action('compose') { composer.present(window) }
      action('open-preferences') { preferences_dialog.present(window) }
      action('shortcuts') { shortcuts_window.present(window) }
      action('quit') { app.quit }
      action('scroll-page-down') { root_view.scroll_page }
      action('scroll-page-up') { root_view.scroll_page(up: true) }

      ACCELS.each { |name, accels| app.set_accels_for_action(name, accels) }
    end

    def action(name, &handler)
      Gio::SimpleAction.new(name).tap do |simple_action|
        simple_action.signal_connect('activate') { handler.call }
        app.add_action(simple_action)
      end
    end
end
