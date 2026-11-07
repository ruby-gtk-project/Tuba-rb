# frozen_string_literal: true

module Utils
  # Utils::Units shortens large counts (follower counts, boost counts, etc.)
  # into compact human strings ("1.3k", "9.8G").
  #
  # Ported from upstream's src/Utils/Units.vala.
  class Units
    SHORT_UNIT_SYMBOLS = {
      none: '',
      thousand: 'k',
      million: 'M',
      billion: 'G'
    }.freeze

    # { top, symbol } pairs, in ascending order, matching upstream's
    # `SHORT_UNITS` table.
    SHORT_UNITS = [
      [1_000, :none],
      [1_000_000, :thousand],
      [1_000_000_000, :million],
      [1_000_000_000_000, :billion]
    ].freeze

    class << self
      def shorten(unit)
        if unit.zero? || (unit < 0 && unit > -1000) || (unit > 0 && unit < 1000)
          unit.to_s
        else
          shorten_large(unit)
        end
      end

      private

      def shorten_large(unit)
        is_negative = unit < 0
        magnitude = is_negative ? -unit : unit

        tier = (1...SHORT_UNITS.length).find { |i| magnitude < SHORT_UNITS[i][0] }

        if tier.nil?
          "♾️" # infinity, matching upstream's "♾️"
        else
          _, symbol = SHORT_UNITS[tier]
          previous_top, = SHORT_UNITS[tier - 1]
          "#{is_negative ? '-' : ''}#{shorten_fraction(magnitude, previous_top)}#{SHORT_UNIT_SYMBOLS[symbol]}"
        end
      end

      def shorten_fraction(magnitude, previous_top)
        shortened_unit = format('%.1f', ((magnitude.to_f / previous_top) * 10.0).truncate / 10.0)

        if shortened_unit.end_with?('0') || shortened_unit.length > 3
          shortened_unit[0...-2]
        else
          shortened_unit
        end
      end
    end
  end
end
