# frozen_string_literal: true

require 'adwaita'

# PreferencesDialog is Tuba's settings window.
#
# Ported from upstream's src/Dialogs/Preferences.vala and
# data/ui/dialogs/preferences.ui. Upstream's dialog mixes rows that bind
# straight to a settings key with rows that need the account/network layer
# this port does not have yet: the visibility/language/content-type/quote-
# policy combo rows (populated from accounts.active and the Mastodon API),
# the Filters page (fetched over the network), UnifiedPush and its push
# subscription PATCH, and the analytics preview dialog (needs GtkSource,
# which this port's gemspec does not declare). All of those are left out.
#
# What's here is every row upstream wires with a plain Settings.bind call:
# General's Appearance, Posts, Behavior and Timelines groups, the font-size
# scale, the proxy entry, the two periodic-update switches, and the
# Notifications page's per-event mute switches plus the Group switch — all
# bound to the same Settings keys upstream's GSettings schema uses
# (lib/settings.rb). The notification type mutes bind to the account-scoped
# "muted-notification-types" array directly, rather than through
# InstanceAccount's KIND_* constants, which this port has no account model
# to supply.
#
class PreferencesDialog < Adwaita::PreferencesDialog
  # [settings key, title, subtitle or nil]
  APPEARANCE_ROWS = [
    ['darken_images_on_dark_mode', 'Darken Images on Dark Mode', nil],
    ['dim_trivial_notifications', 'Dim Trivial Notifications', 'Notifications like favorites and boosts will be less visible'],
    ['enlarge_custom_emojis', 'Large Custom Emojis', nil],
    ['scale_emoji_hover', 'Scale Custom Emojis on Hover', 'Slightly increases the size of custom emojis when you hover over them'],
    ['larger_line_height', 'Large Line Height', 'Increase the line height in posts'],
  ].freeze

  POSTS_ROWS = [
    ['collapse_long_posts', 'Collapse Long Posts', nil],
    ['letterbox_media', 'Letterbox Media', 'Scale down and letterbox media to fill the image containers instead of stretching and cropping them'],
    ['show_sensitive_media', 'Reveal Sensitive Media by Default', nil],
    ['show_spoilers', 'Reveal Spoilers by Default', nil],
    ['show_preview_cards', 'Show Link Preview Cards', nil],
  ].freeze

  BEHAVIOR_ROWS = [
    ['advanced_boost_dialog', 'Advanced Boost Dialog', 'Change boost visibility, quote and confirm boosting'],
    ['use_in_app_browser_if_available', 'Open Links In-App', nil],
    ['strip_tracking', 'Strip Tracking Parameters From Links', 'This option can lead to broken links when enabled'],
    ['reply_to_old_post_reminder', 'Warn before replying to an old post', nil],
    ['copy_private_link_reminder', 'Warn before copying a link to a private post', nil],
    ['boost_alt_text_reminder', 'Warn before boosting a post that includes attachments without alt text', nil],
    ['fetch_remote_media_reminder', 'Warn before fetching media from remote servers', nil],
    ['work_in_background', 'Run in Background', 'Fetch notifications while the app is closed'],
  ].freeze

  TIMELINES_ROWS = [
    ['live_updates', 'Stream Timelines', 'Receive new posts and notifications in real-time'],
    ['public_live_updates', 'Stream Public Timelines', 'This will increase memory usage when browsing high traffic timelines'],
  ].freeze

  ONLINE_SERVICES_ROWS = [
    ['analytics', 'Send Preference Analytics', "Send your preferences to Tuba's developers for popularity research biweekly"],
    ['update_contributors', 'Update Supporters Periodically', "Fetch the list of Tuba's supporters biweekly"],
  ].freeze

  # [event key in muted-notification-types, title]
  NOTIFICATION_MUTE_ROWS = [
    ['new_followers', 'New Followers'],
    ['follow_request', 'New Follower Requests'],
    ['favourite', 'Favorites'],
    ['mention', 'Mentions'],
    ['reblog', 'Boosts'],
    ['poll', 'Poll Results'],
    ['edited', 'Edits'],
    ['quote', 'Quotes'],
    ['quote_update', 'Quote Edits'],
  ].freeze

  FONT_SIZE_DEBOUNCE_MS = 300

  def initialize(settings:)
    super()
    @settings = settings
    @switch_rows = {}
    @mute_rows = {}
    @font_timeout_id = nil
    self.search_enabled = true
  end

  def build
    tap do |dialog|
      dialog.add(general_page)
      dialog.add(notifications_page)
    end
  end

  private

    def general_page
      @general_page ||= Adwaita::PreferencesPage.new.tap do |page|
        page.icon_name = 'tuba-settings-symbolic'
        # translators: group title; contains uncategorized generic items
        page.title = 'General'
        page.add(appearance_group)
        page.add(posts_group)
        page.add(behavior_group)
        page.add(timelines_group)
        page.add(online_services_group)
      end
    end

    def notifications_page
      @notifications_page ||= Adwaita::PreferencesPage.new.tap do |page|
        page.icon_name = 'tuba-bell-outline-symbolic'
        page.title = 'Notifications'
        page.add(push_notifications_group)
      end
    end

    def appearance_group
      @appearance_group ||= Adwaita::PreferencesGroup.new.tap do |group|
        # translators: setting group title; app appearance
        group.title = 'Appearance'
        APPEARANCE_ROWS.each { |key, title, subtitle| group.add(switch_row(key, title, subtitle)) }
        group.add(font_size_row)
      end
    end

    def posts_group
      @posts_group ||= Adwaita::PreferencesGroup.new.tap do |group|
        group.title = 'Posts'
        POSTS_ROWS.each { |key, title, subtitle| group.add(switch_row(key, title, subtitle)) }
      end
    end

    def behavior_group
      @behavior_group ||= Adwaita::PreferencesGroup.new.tap do |group|
        group.title = 'Behavior'
        BEHAVIOR_ROWS.each { |key, title, subtitle| group.add(switch_row(key, title, subtitle)) }
        group.add(proxy_row)
      end
    end

    def timelines_group
      @timelines_group ||= Adwaita::PreferencesGroup.new.tap do |group|
        group.title = 'Timelines'
        TIMELINES_ROWS.each { |key, title, subtitle| group.add(switch_row(key, title, subtitle)) }

        # Upstream binds public_live_updates' sensitivity to live_updates'
        # active state (bind-property in preferences.ui); mirrored here with
        # a signal rather than a GLib::Binding.
        public_updates_row = switch_row('public_live_updates', nil, nil)
        public_updates_row.sensitive = @settings.live_updates?
        switch_row('live_updates', nil, nil).signal_connect('notify::active') do |row|
          public_updates_row.sensitive = row.active?
        end
      end
    end

    def online_services_group
      @online_services_group ||= Adwaita::PreferencesGroup.new.tap do |group|
        # translators: setting group about tuba-related network options
        group.title = 'Online Services'
        ONLINE_SERVICES_ROWS.each { |key, title, subtitle| group.add(switch_row(key, title, subtitle)) }
      end
    end

    def push_notifications_group
      @push_notifications_group ||= Adwaita::PreferencesGroup.new.tap do |group|
        # translators: Push Notifications are the desktop ones / not the in-app ones. Noun.
        group.title = 'Push Notifications'
        NOTIFICATION_MUTE_ROWS.each { |event, title| group.add(mute_row(event, title)) }
        group.add(switch_row('group_push_notifications', 'Group', 'Combine recently pushed notifications of the same type and post into one'))
      end
    end

    # A single switch row, bound straight to a global Settings key. Rows are
    # memoized by key so a row referenced from two groups (public_live_updates'
    # sensitivity binding) is the same widget both times.
    def switch_row(key, title, subtitle)
      @switch_rows[key] ||= Adwaita::SwitchRow.new.tap do |row|
        row.title = title if title
        row.subtitle = subtitle if subtitle
        row.active = @settings.public_send(:"#{key}?")
        row.signal_connect('notify::active') { @settings.public_send(:"#{key}=", row.active?) }
      end
    end

    # The notification-mute rows invert the stored semantics: upstream only
    # lists an event in muted-notification-types when the switch is OFF, so
    # the row starts active unless the event is already muted.
    def mute_row(event, title)
      @mute_rows[event] ||= Adwaita::SwitchRow.new.tap do |row|
        row.title = title
        row.active = !@settings.muted_notification_types.include?(event)
        row.signal_connect('notify::active') { update_muted_notification_type(event, row.active?) }
      end
    end

    def update_muted_notification_type(event, active)
      muted = @settings.muted_notification_types.dup
      if active
        muted.delete(event)
      elsif !muted.include?(event)
        muted << event
      end
      @settings.muted_notification_types = muted
    end

    def font_adjustment
      @font_adjustment ||= Gtk::Adjustment.new(@settings.status_font_size, 0.8, 2.0, 0.1, 1.0, 0)
    end

    def font_scale
      @font_scale ||= Gtk::Scale.new(:horizontal, font_adjustment).tap do |scale|
        scale.draw_value = true
        scale.hexpand = true
        scale.signal_connect('value-changed') { on_font_adjustment_value_changed }
      end
    end

    def font_size_row
      @font_size_row ||= Adwaita::ActionRow.new.tap do |row|
        # translators: setting that shows a scale for the user to set the font size
        row.title = 'Font Size'
        # translators: setting subtitle on what font size changing entails; make sure it's clear only the font size of the posts changes, not the whole UI
        row.subtitle = 'Set the text size used in posts'
        row.add_suffix(font_scale)
      end
    end

    # Upstream debounces the adjustment's value-changed by 300ms before
    # writing to settings, so dragging the slider does not spam a write per
    # frame.
    def on_font_adjustment_value_changed
      GLib::Source.remove(@font_timeout_id) if @font_timeout_id
      @font_timeout_id = GLib::Timeout.add(FONT_SIZE_DEBOUNCE_MS) do
        @settings.status_font_size = font_adjustment.value
        @font_timeout_id = nil
        GLib::Source::REMOVE
      end
    end

    def proxy_row
      @proxy_row ||= Adwaita::EntryRow.new.tap do |row|
        # translators: probably leave it as is. It's a networking term that might not translate nicely without losing its meaning
        row.title = 'Proxy'
        row.text = @settings.proxy
        row.show_apply_button = false
        row.signal_connect('apply') { @settings.proxy = row.text }
        row.signal_connect('notify::text') { @settings.proxy = row.text }
      end
    end
end
