# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'adwaita'

# Settings holds the same keys as upstream's two GSettings schemas.
#
# Ported from upstream's data/dev.geopjr.Tuba.gschema.xml and
# src/Services/Settings.vala. Upstream has a global schema (dev.geopjr.Tuba)
# and a per-account one (dev.geopjr.Tuba.Account) relocated to
# /dev/geopjr/Tuba/accounts/<uuid>/, and Settings.vala binds every key to a
# property of itself, forwarding the account-scoped ones to whichever account
# is active.
#
# GSettings needs a schema compiled into the system's glib-2.0/schemas
# directory; requiring an install step to run the app from a checkout is worse
# than the alternative, so the same keys, defaults and semantics are backed by
# one JSON file under XDG_CONFIG_HOME. The account-scoped keys live in a
# nested object keyed by account UUID, which is what upstream's relocated
# schema does with its path.
#
class Settings
  # Hashed handles of Tuba's contributors, shipped as the default of the
  # "contributors" key so the app can mark them before the first fetch.
  CONTRIBUTORS = %w[
    2964685538 2486375860 1741071036 3456423266 1352322503
    4002061011 3177176442 2813905310 3163563143 719735140
    2386917030 987913018 3320460562 4170269605 3355903820
    580879396 3096862973 136476033 716517886 4041964504
  ].freeze

  # The global schema's keys.
  DEFAULTS = {
    'active-account'                  => '',
    'color-scheme'                    => 'system',
    'work-in-background'              => false,
    'timeline-page-size'              => 20,
    'live-updates'                    => true,
    'public-live-updates'             => false,
    'show-spoilers'                   => false,
    'show-preview-cards'              => true,
    'larger-font-size'                => false,
    'larger-line-height'              => false,
    'scale-emoji-hover'               => true,
    'aggressive-resolving'            => false,
    'strip-tracking'                  => true,
    'letterbox-media'                 => false,
    'media-viewer-expand-pictures'    => true,
    'enlarge-custom-emojis'           => false,
    'use-blurhash'                    => true,
    'show-sensitive-media'            => false,
    'group-push-notifications'        => false,
    'advanced-boost-dialog'           => false,
    'reply-to-old-post-reminder'      => true,
    'boost-alt-text-reminder'         => true,
    'fetch-remote-media-reminder'     => true,
    'fetch-remote-media-default'      => false,
    'copy-private-link-reminder'      => true,
    'spellchecker-enabled'            => true,
    'darken-images-on-dark-mode'      => false,
    'dim-trivial-notifications'       => false,
    'blur-sensitive-media'            => true,
    'media-viewer-last-used-volume'   => 1.0,
    'monitor-network'                 => true,
    'proxy'                           => '',
    'analytics'                       => false,
    'update-contributors'             => false,
    'last-analytics-update'           => '',
    'last-contributors-update'        => '',
    'contributors'                    => CONTRIBUTORS,
    'status-aria-verbosity'           => 3,
    'use-in-app-browser-if-available' => true,
    'collapse-long-posts'             => true,
    'auto-detect-features'            => true,
    'show-interaction-counters'       => true,
    'extract-alt-from-metadata'       => true,
    'status-font-size'                => 1.0,
    'window-w'                        => 600,
    'window-h'                        => 700,
    'window-maximized'                => false,
  }.freeze

  # The per-account schema's keys. Upstream reaches these through properties
  # on Settings that forward to the active account's own GSettings instance,
  # which is what #account_value and #set_account_value do here.
  #
  # "default-language" and "default-quote-policy" have no key in the schema
  # file: Settings.Account declares them as plain properties with the defaults
  # below, so they are account-scoped all the same.
  ACCOUNT_DEFAULTS = {
    'default-post-visibility'     => 'public',
    'default-content-type'        => 'text/plain',
    'default-language'            => 'en',
    'default-quote-policy'        => 'followers',
    'account-suggestions'         => true,
    'unifiedpush-enabled'         => false,
    'muted-notification-types'    => [],
    'recently-used-custom-emojis' => [],
    'recent-searches'             => [],
    'notification-filters'        => [],
    'favorite-lists-ids'          => [],
    'favorite-tags-ids'           => [],
    'hashtag-lists'               => [],
  }.freeze

  # Upstream's Settings.SENSITIVE_KEYS: left out of the analytics payload and
  # of the developer console's settings dump.
  SENSITIVE_KEYS = %w[
    proxy
    active-account
    last-analytics-update
    last-contributors-update
    contributors
  ].freeze

  # Upstream's Tuba.ColorScheme enum and its to_adwaita_scheme/to_string.
  COLOR_SCHEMES = {
    'system' => :default,
    'light'  => :force_light,
    'dark'   => :force_dark,
  }.freeze

  COLOR_SCHEME_LABELS = {
    'system' => 'Follow System',
    'light'  => 'Light',
    'dark'   => 'Dark',
  }.freeze

  def initialize(path: nil)
    @path = path || default_path
    @values = DEFAULTS.merge(read)
    @values['accounts'] = accounts_from(@values['accounts'])
  end

  def location = @path

  def [](key) = @values.fetch(key.to_s, DEFAULTS[key.to_s])

  def []=(key, value)
    @values[key.to_s] = value
    write
    value
  end

  # Named accessors for the global keys, so callers do not repeat the string
  # keys. A boolean key also gets a predicate.
  DEFAULTS.each_key do |key|
    method_name = key.tr('-', '_')
    define_method(method_name) { self[key] }
    define_method(:"#{method_name}=") { |value| self[key] = value }
    if [true, false].include?(DEFAULTS[key])
      define_method(:"#{method_name}?") { self[key] == true }
    end
  end

  # The account-scoped keys read and write under the active account's UUID.
  ACCOUNT_DEFAULTS.each_key do |key|
    method_name = key.tr('-', '_')
    define_method(method_name) { account_value(key) }
    define_method(:"#{method_name}=") { |value| set_account_value(key, value) }
    if [true, false].include?(ACCOUNT_DEFAULTS[key])
      define_method(:"#{method_name}?") { account_value(key) == true }
    end
  end

  def account_value(key, uuid: active_account)
    account_values(uuid).fetch(key.to_s, ACCOUNT_DEFAULTS[key.to_s])
  end

  def set_account_value(key, value, uuid: active_account)
    account_values(uuid)[key.to_s] = value
    write
    value
  end

  # Upstream drops an account's whole relocated schema path when the account
  # is forgotten.
  def forget_account(uuid)
    @values['accounts'].delete(uuid.to_s)
    write
  end

  # The Adwaita enum value for the stored nick, for Adw.StyleManager.
  def adwaita_color_scheme = COLOR_SCHEMES.fetch(color_scheme, :default)

  # The user-facing label of the stored nick, for the preferences dialog.
  def color_scheme_label = COLOR_SCHEME_LABELS.fetch(color_scheme, COLOR_SCHEME_LABELS['system'])

  # Upstream's Settings.to_debug_json: every global key except the sensitive
  # ones, stringified, for the developer console and the analytics payload.
  def debug_values
    DEFAULTS.each_key.reject { |key| SENSITIVE_KEYS.include?(key) }.to_h do |key|
      [key, self[key].to_s]
    end
  end

  # Restores the window geometry recorded by the previous run. Upstream's
  # Saveable interface does this from window-w, window-h and window-maximized.
  def apply_to(window)
    window.set_default_size(self['window-w'], self['window-h'])
    if self['window-maximized']
      window.maximize
    end
  end

  # Records the window geometry, skipping the size while maximized so the
  # restored size is the one the user actually chose.
  def remember(window)
    @values['window-maximized'] = window.maximized?
    unless window.maximized?
      @values['window-w'] = window.default_width
      @values['window-h'] = window.default_height
    end
    write
  end

  private

    def accounts_from(stored)
      if stored.is_a?(Hash)
        stored
      else
        {}
      end
    end

    def account_values(uuid)
      @values['accounts'][uuid.to_s] ||= {}
    end

    def default_path
      File.join(
        ENV.fetch('XDG_CONFIG_HOME', File.expand_path('~/.config')),
        'tuba-rb',
        'settings.json',
      )
    end

    def read
      if File.exist?(@path)
        JSON.parse(File.read(@path))
      else
        {}
      end
    rescue JSON::ParserError => e
      warn "Error parsing #{@path}: #{e.message}"
      {}
    end

    def write
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, JSON.pretty_generate(@values))
    end
end
