# frozen_string_literal: true

# Widgetizable is the mixin every model object implements so a view can turn
# it into a row without knowing its class.
#
# Ported from upstream's src/Widgets/Widgetizable.vala, which declares two
# interfaces: BasicWidgetizable, with only a widget factory, and Widgetizable,
# which adds opening the thing the object stands for. Upstream's default
# implementations assert (to_widget) and warn (open); the Ruby versions raise
# and warn the same way, so a model that forgets one is loud rather than
# silently empty.
#
module BasicWidgetizable
  # Builds the widget that stands for this object in a list.
  def to_widget
    raise "#{self.class} must define #to_widget"
  end
end

module Widgetizable
  include BasicWidgetizable

  # Opens whatever this object points at — a post's thread, a profile, a tag's
  # timeline. Upstream warns instead of asserting, because a model that is
  # only ever shown is legitimate.
  def open
    warn "#{self.class} did not provide a way to open it!"
  end

  # Opening something that belongs to another instance: upstream's default
  # ignores the account and opens locally, and the entities that can be
  # resolved remotely (accounts, statuses) override it.
  def resolve_open(_account) = open
end
