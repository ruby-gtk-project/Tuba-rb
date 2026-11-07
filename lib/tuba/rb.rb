# frozen_string_literal: true

require_relative 'rb/version'

# The part of Tuba that loads without a display.
#
# `require 'gtk4'` initialises GTK at require time and raises Gtk::InitError
# when there is no display server, so anything that reaches a widget class
# cannot be loaded by a plain `ruby -e` or by a test process on a headless
# machine. The split is along that line and no other:
#
#   require 'tuba/rb'   the gem's version constant — nothing else lives on
#                       this side of the split yet (the display-free ported
#                       units, Utils::Counting/DateTime/TagExtractor/Units,
#                       are required directly by their own specs; see
#                       spec/utils_*_spec.rb);
#   require 'tuba'      the application and every widget, which needs a
#                       display.
#
# This is also the file the gem's version constant lives under, which is why
# spec/spec_helper.rb requires it: specs for the display-free half need
# nothing more, and the ones that drive widgets ask for 'tuba' themselves.
