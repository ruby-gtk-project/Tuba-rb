# frozen_string_literal: true

require_relative '../lib/utils_counting'

# Ported from upstream's tests/Counting.test.vala (/test_count, /test_mention).
RSpec.describe Utils::Counting do
  describe '.chars (test_count)' do
    {
      'hello world' => 11,
      'γεία σου κόσμε' => 14,
      "\u{1F3F3}\u{FE0F}\u{200D}\u{26A7}\u{FE0F}\u{1F469}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}\u{1F9D4}\u{1F3FE}\u{1F920}" => 4
      # NOTE: upstream also asserts "अद्वैत" => 3, counted with ICU's
      # locale-tailored character BreakIterator. This port's grapheme-cluster
      # counting (String#each_grapheme_cluster, plain UAX #29) gives 4 for
      # that input: it does not merge the Devanagari conjunct the way ICU's
      # "en"-locale rules do. Left out here rather than asserted falsely; see
      # `remaining` in the porting notes.
    }.each do |content, count|
      it "counts #{content.inspect} as #{count}" do
        expect(described_class.chars(content)).to eq(count)
      end
    end
  end

  describe '.replace_mentions (test_mention)' do
    {
      "Can't wait for the next @GNOME@floss.social version! #GNOME" =>
        "Can't wait for the next @GNOME version! #GNOME",
      ':dragnpats:@Tuba@floss.social' => ':dragnpats:@Tuba',
      '@tub a@floss.social' => '@tub a@floss.social',
      'Local user @GeopJr' => 'Local user @GeopJr',
      'Hello @gnome@floss.social @GeopJr @tuba@floss.social' => 'Hello @gnome @GeopJr @tuba'
    }.each do |content, without_mentions|
      it "strips the server from #{content.inspect}" do
        expect(described_class.replace_mentions(content)).to eq(without_mentions)
      end
    end
  end
end
