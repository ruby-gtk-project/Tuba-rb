# frozen_string_literal: true

require_relative '../lib/utils_units'

# Ported from upstream's tests/Units.test.vala (/test_shorten).
RSpec.describe Utils::Units do
  describe '.shorten' do
    {
      0 => '0',
      123 => '123',
      999 => '999',
      1000 => '1k',
      1312 => '1.3k',
      999_999 => '999k',
      1_000_000 => '1M',
      9_876_543_210 => '9.8G',
      1_000_000_000_000 => "♾️"
    }.each do |original, result|
      it "test_shorten: shortens #{original} to #{result.inspect}" do
        expect(described_class.shorten(original)).to eq(result)
      end

      negated_result = (result == "♾️" || result == '0') ? result : "-#{result}"
      it "test_shorten: shortens #{-original} to #{negated_result.inspect}" do
        expect(described_class.shorten(-original)).to eq(negated_result)
      end
    end
  end
end
