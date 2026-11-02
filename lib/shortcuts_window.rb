# frozen_string_literal: true

require 'adwaita'

# ShortcutsWindow lists the keyboard shortcuts.
#
# Ported from upstream's data/gtk/shortcuts-dialog.ui, the AdwShortcutsDialog
# that Adwaita's "app.shortcuts" action picks up from the gtk/ resource
# directory. The three sections, their order and their items are the file's.
#
# An item is described either by the action it triggers, in which case
# Adwaita looks the accelerator up from the application's accel map, or by a
# literal accelerator for the shortcuts that are handled by a widget rather
# than an action.
#
class ShortcutsWindow < Adwaita::ShortcutsDialog
  # [title, action name] or [title, nil, accelerator].
  SECTIONS = {
    'General'      => [
      # translators: shortcut description
      ['Show Preferences', 'app.open-preferences'],
      # translators: shortcut description
      ['Compose New Post', 'app.compose'],
      ['Refresh', 'app.refresh'],
      ['Search', 'app.search'],
      # translators: shortcut description; as in go to the previous page/view
      ['Go Back', nil, '<alt>Left Escape'],
      # translators: shortcut description
      ['Show Keyboard Shortcuts', 'app.shortcuts'],
      # translators: shortcut description
      ['Close Window', 'window.close'],
      ['Quit', 'app.quit'],
      # translators: shortcut description; opens the about dialog
      ['About', 'app.about'],
      # translators: shortcut description
      ['Scroll Up', 'app.scroll-page-up'],
      # translators: shortcut description
      ['Scroll Down', 'app.scroll-page-down'],
    ],
    # translators: shortcut group description
    'Composer'     => [
      # translators: shortcut description; commit as post what you wrote
      #              inside the composer (same as clicking the post button)
      ['Commit', nil, '<ctrl>Return'],
    ],
    'Media Viewer' => [
      ['Fullscreen', nil, 'F11'],
      ['Zoom In', nil, '<ctrl>plus <ctrl>equal'],
      ['Zoom Out', nil, '<ctrl>minus <ctrl>underscore'],
      ['Previous Attachment', nil, 'Left KP_Left'],
      ['Next Attachment', nil, 'Right KP_Right'],
    ],
  }.freeze

  def initialize
    super()
    self.title = 'Keyboard Shortcuts'
  end

  def build
    tap do |dialog|
      SECTIONS.each do |title, items|
        dialog.add(section(title, items))
      end
    end
  end

  private

    def section(title, items)
      Adwaita::ShortcutsSection.new.tap do |section|
        section.title = title
        items.each { |description| section.add(item(*description)) }
      end
    end

  # Positional, not keyword, arguments, and an empty accelerator rather than
  # nil: a no-argument new advertises the signature as "title: utf8,
  # accelerator: utf8", and passing nil for either raises.
    def item(title, action_name, accelerator = '')
      Adwaita::ShortcutsItem.new(title, accelerator).tap do |shortcut|
        unless action_name.nil?
          shortcut.action_name = action_name
        end
      end
    end
end
