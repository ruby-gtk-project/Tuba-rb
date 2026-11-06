# frozen_string_literal: true

require 'gtk4'

# VoteCheckButton is the check button a poll option's row uses to let the
# viewer pick it.
#
# Ported from upstream's src/Widgets/VoteCheckButton.vala, a Gtk.CheckButton
# that adds a `poll_title` property (read by screen readers alongside the
# option's own label) and always centers itself vertically with the
# "selection-mode" CSS class, matching the row it sits in.
#
class VoteCheckButton < Gtk::CheckButton
  attr_accessor :poll_title

  def initialize(*)
    super
    self.valign = :center
    self.css_classes = ['selection-mode']
  end
end
