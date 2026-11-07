# frozen_string_literal: true

require 'time'

# Utils::DateTime turns an ISO 8601 timestamp into the short relative strings
# shown next to statuses, polls and account ages ("2h", "Yesterday",
# "expires soon").
#
# Ported from upstream's src/Utils/DateTime.vala. Upstream works against
# GLib.DateTime; this port uses Ruby's Time, which has the same local-time and
# calendar-field semantics upstream relies on (get_year, get_month,
# get_day_of_year).
module Utils
  class DateTime
    MINUTE = 60
    HOUR = 60 * 60
    DAY = 60 * 60 * 24

    class << self
      def humanize_left(iso8601)
        if iso8601.nil?
          ''
        else
          date = Time.parse(iso8601)
          now = Time.now
          delta = date - now # seconds; positive when date is in the future

          if delta < 0
            humanize(iso8601)
          elsif delta <= MINUTE
            'expires soon'
          elsif delta < HOUR
            "#{(delta / MINUTE).to_i}m left"
          elsif delta <= DAY
            "#{(delta / HOUR).to_i}h left"
          elsif delta <= (DAY * 60)
            "#{(delta / DAY).to_i}d left"
          else
            date.localtime.strftime('expires on %b %-e, %Y')
          end
        end
      end

      def humanize_ago(iso8601)
        date = Time.parse(iso8601)
        now = Time.now
        delta = now - date # seconds; positive when date is in the past

        if delta < 0
          date.localtime.strftime('expires on %b %-e, %Y %H:%M')
        elsif delta <= MINUTE
          'expired on just now'
        elsif delta < HOUR
          "expired #{(delta / MINUTE).to_i}m ago"
        elsif delta <= DAY
          "expired #{(delta / HOUR).to_i}h ago"
        elsif same_day?(now, date + DAY)
          'expired yesterday'
        elsif date.localtime.year == now.year
          date.localtime.strftime('expired on %b %-e')
        else
          date.localtime.strftime('expired on %b %-e, %Y')
        end
      end

      def humanize(iso8601)
        date = Time.parse(iso8601)
        now = Time.now
        delta = now - date

        if delta < 0
          date.localtime.strftime('%b %-e, %Y %H:%M')
        elsif delta <= MINUTE
          'Just now'
        elsif delta < HOUR
          "#{(delta / MINUTE).to_i}m"
        elsif delta <= DAY
          "#{(delta / HOUR).to_i}h"
        elsif same_day?(now, date + DAY)
          'Yesterday'
        elsif date.localtime.year == now.year
          date.localtime.strftime('%b %-e')
        else
          date.localtime.strftime('%b %-e, %Y')
        end
      end

      def is_3_months_old(iso8601)
        date = Time.parse(iso8601)
        now = Time.now

        if (now - date) < 0
          false
        else
          (now.month + (12 * (now.year - date.localtime.year)) - date.localtime.month) > 3
        end
      end

      def same_day?(d1, d2)
        d1.localtime.yday == d2.localtime.yday && d1.localtime.year == d2.localtime.year
      end
    end
  end
end
