# frozen_string_literal: true

require 'adwaita'

# ProfileMenu is the menu behind the button in a profile's header bar.
#
# Ported from upstream's data/ui/menus.ui, which declares one menu model,
# "profile-menu". Every item targets an action in the "view" group that
# Views.Profile installs on the window, so the menu is the same whichever
# profile it is opened on.
#
# The first section carries the "circular-buttons" display hint, which is what
# makes Mention, Direct Message and Copy Handle render as a row of round
# icon buttons at the top of the popover instead of as list items. The items
# that only make sense for someone else's profile carry "hidden-when":
# "action-disabled", so they disappear when the profile view disables them.
#
class ProfileMenu
  CIRCULAR_BUTTONS = 'circular-buttons'
  HIDDEN_WHEN_DISABLED = 'action-disabled'

  # [label, action, target or nil, verb icon]
  INTERACTION_ITEMS = [
    ['Mention', 'view.mention', 'public', 'tuba-online-symbolic'],
    ['Direct Message', 'view.mention', 'direct', 'tuba-mail-unread-symbolic'],
    ['Copy Handle', 'view.copy_handle', nil, 'edit-copy-symbolic'],
  ].freeze

  # [label, action, hidden when disabled]
  PROFILE_ITEMS = [
    ['Open in Browser', 'view.open_in_browser', false],
    # translators: option on profiles, when enabled the user will get
    #              notifications every time this profile posts something
    ['Receive Post Notifications', 'view.notify_on_post', true],
    # translators: used in profile actions for endorsing a user
    ['Feature on Profile', 'view.endorsed', true],
    # translators: 'Collections' is a Mastodon feature
    ['Collections', 'view.collections', true],
    # translators: headerbar menu item that edits the private note of the
    #              profile it's on
    ['Private Note…', 'view.add-note', true],
  ].freeze

  MODERATION_ITEMS = [
    # translators: option on profiles that when enabled will hide this user's
    #              posts from your Home timeline
    ['Hide Boosts', 'view.hiding_reblogs', true],
    # translators: whether to mute someone
    ['Mute', 'view.muting', false],
  ].freeze

  BLOCKING_ITEMS = [
    # translators: whether to block someone
    ['Block', 'view.blocking', false],
    # translators: whether to block someone's whole instance; you may replace
    #              "domain" with "server" or "instance"
    ['Block Domain', 'view.domain_blocking', false],
    # translators: context is 'verb'
    ['Report', 'view.report', false],
  ].freeze

  TIMELINE_ITEMS = [
    ['Lists', 'view.ar_list', true],
  ].freeze

  # The menu model, ready to hand to a Gtk::MenuButton.
  def build
    menu.tap do |model|
      model.append_item(hinted_section(interaction_section, CIRCULAR_BUTTONS))
      PROFILE_ITEMS.each { |description| model.append_item(item(*description)) }
      model.append_section('Moderation', moderation_section)
      model.append_section('Timeline', timeline_section)
    end
  end

  def menu = @menu ||= Gio::Menu.new

  private

    def interaction_section
      Gio::Menu.new.tap do |section|
        INTERACTION_ITEMS.each do |label, action, target, verb_icon|
          section.append_item(
            interaction_item(
              label,
              action,
              target,
              verb_icon,
            ),
          )
        end
      end
    end

    def moderation_section
      Gio::Menu.new.tap do |section|
        MODERATION_ITEMS.each { |description| section.append_item(item(*description)) }
        section.append_section(nil, blocking_section)
      end
    end

    def blocking_section
      Gio::Menu.new.tap do |section|
        BLOCKING_ITEMS.each { |description| section.append_item(item(*description)) }
      end
    end

    def timeline_section
      Gio::Menu.new.tap do |section|
        TIMELINE_ITEMS.each { |description| section.append_item(item(*description)) }
      end
    end

    def item(label, action, hidden_when_disabled)
      Gio::MenuItem.new(label, action).tap do |menu_item|
        if hidden_when_disabled
          menu_item.set_attribute_value('hidden-when', GLib::Variant.new(HIDDEN_WHEN_DISABLED))
        end
      end
    end

  # Mention is the same action twice, told apart by its target: the
  # visibility the composer opens with.
    def interaction_item(label, action, target, verb_icon)
      Gio::MenuItem.new(label, nil).tap do |menu_item|
        if target.nil?
          menu_item.set_detailed_action(action)
        else
          menu_item.set_action_and_target_value(action, GLib::Variant.new(target))
        end
        menu_item.set_attribute_value('verb-icon', GLib::Variant.new(verb_icon))
      end
    end

  # A section's own attributes — here the display hint — can only be set on
  # the menu item that carries the section, so the section is appended as an
  # item rather than with append_section.
    def hinted_section(section, hint)
      Gio::MenuItem.new(nil, nil).tap do |menu_item|
        menu_item.set_section(section)
        menu_item.set_attribute_value('display-hint', GLib::Variant.new(hint))
      end
    end
end
