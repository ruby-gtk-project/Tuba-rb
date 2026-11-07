# frozen_string_literal: true

require_relative '../lib/utils_date_time'
require 'time'

# Ported from upstream's tests/DateTime.test.vala
# (/test_left, /test_ago, /test_humanize, /test_3_months).
#
# Upstream builds its fixture dates relative to "now" at test-run time; this
# port does the same with Ruby's Time so the relative cases (one day from now,
# one hour ago, etc.) hold regardless of when the suite runs. Only the fixed
# 2002-06-29 case has a literal expected string.
RSpec.describe Utils::DateTime do
  def iso(time)
    time.iso8601
  end

  describe 'a fixed past date (test_left, test_ago, test_humanize)' do
    let(:fixed) { Time.local(2002, 6, 29, 18, 0, 0) }

    it 'test_left' do
      expect(described_class.humanize_left(iso(fixed))).to eq('Jun 29, 2002')
    end

    it 'test_ago' do
      expect(described_class.humanize_ago(iso(fixed))).to eq('expired on Jun 29, 2002')
    end

    it 'test_humanize' do
      expect(described_class.humanize(iso(fixed))).to eq('Jun 29, 2002')
    end
  end

  describe 'relative dates (test_left, test_ago, test_humanize)' do
    let(:now) { Time.now }

    it 'one day from now: 23h left' do
      expect(described_class.humanize_left(iso(now + (24 * 60 * 60)))).to eq('23h left')
    end

    it 'one day ago: Yesterday / expired yesterday' do
      past = now - (24 * 60 * 60)
      expect(described_class.humanize_left(iso(past))).to eq('Yesterday')
      expect(described_class.humanize_ago(iso(past))).to eq('expired yesterday')
      expect(described_class.humanize(iso(past))).to eq('Yesterday')
    end

    it 'one hour from now: 59m left' do
      expect(described_class.humanize_left(iso(now + 3600))).to eq('59m left')
    end

    it 'one hour ago: 1h / expired 1h ago' do
      past = now - 3600
      expect(described_class.humanize_left(iso(past))).to eq('1h')
      expect(described_class.humanize_ago(iso(past))).to eq('expired 1h ago')
    end

    it 'two minutes from now: 1m left' do
      expect(described_class.humanize_left(iso(now + 120))).to eq('1m left')
    end

    it 'two minutes ago: 2m / expired 2m ago' do
      past = now - 120
      expect(described_class.humanize_left(iso(past))).to eq('2m')
      expect(described_class.humanize_ago(iso(past))).to eq('expired 2m ago')
    end

    it 'twenty seconds from now: expires soon' do
      expect(described_class.humanize_left(iso(now + 20))).to eq('expires soon')
    end

    it 'twenty seconds ago: Just now / expired on just now' do
      past = now - 20
      expect(described_class.humanize_left(iso(past))).to eq('Just now')
      expect(described_class.humanize_ago(iso(past))).to eq('expired on just now')
    end
  end

  describe '.is_3_months_old (test_3_months)' do
    let(:now) { Time.now }

    def add_months(time, months)
      total = (time.month - 1) + months
      year = time.year + (total / 12)
      month = (total % 12) + 1
      Time.local(year, month, time.day, time.hour, time.min, time.sec)
    rescue ArgumentError
      # Overflowed into a shorter month (e.g. Jan 31 + 1 month); upstream's
      # GLib.DateTime.add_months clamps the day, so do the same.
      Time.local(year, month, [time.day, 28].min, time.hour, time.min, time.sec)
    end

    it 'is false for a date one day in the future' do
      expect(described_class.is_3_months_old(iso(now + (24 * 60 * 60)))).to be(false)
    end

    it 'is false for a date two months in the future' do
      expect(described_class.is_3_months_old(iso(add_months(now, 2)))).to be(false)
    end

    it 'is false for a date two months in the past' do
      expect(described_class.is_3_months_old(iso(add_months(now, -2)))).to be(false)
    end

    it 'is false for a date three months in the future' do
      expect(described_class.is_3_months_old(iso(add_months(now, 3)))).to be(false)
    end

    it 'is false for a date three months in the past' do
      expect(described_class.is_3_months_old(iso(add_months(now, -3)))).to be(false)
    end

    it 'is true for a date thirteen months in the past' do
      expect(described_class.is_3_months_old(iso(add_months(now, -13)))).to be(true)
    end
  end
end
