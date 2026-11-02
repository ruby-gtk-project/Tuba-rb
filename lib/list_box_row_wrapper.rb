# frozen_string_literal: true

require 'adwaita'

# ListBoxRowWrapper is a list row that can tell its view it was opened.
#
# Ported from upstream's src/Widgets/ListBoxRowWrapper.vala, a Gtk.ListBoxRow
# whose only addition is an "open" signal. Upstream's ContentBase reacts to a
# row activation by emitting that signal by name on the row, so any row type
# can answer it without a common base class.
#
# GObject signals cannot be declared from Ruby without registering a new
# GType, so the signal is a plain Ruby callback list: #on_open subscribes and
# #open notifies, which is exactly the two halves the Vala signal gives.
#
class ListBoxRowWrapper < Gtk::ListBoxRow
  # Subscribes to the row being opened. Returns the row, so a caller can keep
  # building in one expression.
  def on_open(&handler)
    tap { open_handlers << handler }
  end

  # Notifies every subscriber. Upstream's ContentBase calls this when the row
  # is activated.
  def open
    open_handlers.each(&:call)
  end

  private

    def open_handlers = @open_handlers ||= []
end
