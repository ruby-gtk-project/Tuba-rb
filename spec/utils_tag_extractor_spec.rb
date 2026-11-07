# frozen_string_literal: true

require_relative '../lib/utils_tag_extractor'

# Ported from upstream's tests/TagExtractor.test.vala (/test_extractor).
RSpec.describe Utils::TagExtractor do
  def tag_pairs(result)
    result.extracted_tags&.map { |t| [t.tag, t.link] }
  end

  it 'extracts a trailing paragraph of space-separated hashtag links' do
    source = "I am a <a href='https://gnome.org/'>pango</a> markup label\n\n" \
      "<a href='https://gnome.org/tags/opensource'>#opensource</a> " \
      "<a href='https://gnome.org/tags/cookies'>#cookies</a> " \
      "<a href='https://gnome.org/tags/frogs'>#frogs</a> " \
      "<a href='https://gnome.org/tags/sunny'>#sunny</a>"

    result = described_class.from_string(source)

    expect(result.input_without_tags).to eq("I am a <a href='https://gnome.org/'>pango</a> markup label")
    expect(tag_pairs(result)).to eq([
      %w[opensource https://gnome.org/tags/opensource],
      %w[cookies https://gnome.org/tags/cookies],
      %w[frogs https://gnome.org/tags/frogs],
      %w[sunny https://gnome.org/tags/sunny]
    ])
  end

  it 'extracts hashtag links with no spaces between them' do
    source = "Same as before but no spaces between tags\n\n" \
      "<a href='https://gnome.org/tags/opensource'>#opensource</a>" \
      "<a href='https://gnome.org/tags/cookies'>#cookies</a>" \
      "<a href='https://gnome.org/tags/frogs'>#frogs</a>" \
      "<a href='https://gnome.org/tags/sunny'>#sunny</a>"

    result = described_class.from_string(source)

    expect(result.input_without_tags).to eq('Same as before but no spaces between tags')
    expect(tag_pairs(result).length).to eq(4)
  end

  it 'extracts nothing when the trailing paragraph has a newline in the middle' do
    source = "Same as before but there's a newline in the middle\n\n" \
      "<a href='https://gnome.org/tags/opensource'>#opensource</a>" \
      "<a href='https://gnome.org/tags/cookies'>#cookies</a>\n" \
      "<a href='https://gnome.org/tags/frogs'>#frogs</a>" \
      "<a href='https://gnome.org/tags/sunny'>#sunny</a>"

    result = described_class.from_string(source)

    expect(result.input_without_tags).to be_nil
    expect(result.extracted_tags).to be_nil
  end

  it 'extracts nothing when the trailing paragraph has non-hashtag text in it' do
    source = "Same as before but there's non-hashtag text in the middle\n\n" \
      "<a href='https://gnome.org/tags/opensource'>#opensource</a>" \
      "<a href='https://gnome.org/tags/cookies'>#cookies</a> hello? " \
      "<a href='https://gnome.org/tags/frogs'>#frogs</a>" \
      "<a href='https://gnome.org/tags/sunny'>#sunny</a>"

    result = described_class.from_string(source)

    expect(result.input_without_tags).to be_nil
    expect(result.extracted_tags).to be_nil
  end

  it 'extracts nothing when one of the links has no leading #' do
    source = "Same as before but there's a hashtag without #\n\n" \
      "<a href='https://gnome.org/tags/opensource'>#opensource</a>" \
      "<a href='https://gnome.org/tags/cookies'>#cookies</a> hello? " \
      "<a href='https://gnome.org/tags/frogs'>frogs</a>" \
      "<a href='https://gnome.org/tags/sunny'>#sunny</a>"

    result = described_class.from_string(source)

    expect(result.input_without_tags).to be_nil
    expect(result.extracted_tags).to be_nil
  end

  it 'extracts nothing when there is only a single newline before the tags' do
    source = "Same as before but single newline\n" \
      "<a href='https://gnome.org/tags/opensource'>#opensource</a>" \
      "<a href='https://gnome.org/tags/cookies'>#cookies</a>" \
      "<a href='https://gnome.org/tags/frogs'>#frogs</a>" \
      "<a href='https://gnome.org/tags/sunny'>#sunny</a>"

    result = described_class.from_string(source)

    expect(result.input_without_tags).to be_nil
    expect(result.extracted_tags).to be_nil
  end

  it 'extracts an empty tag list when the trailing paragraph is blank' do
    source = "Same as before but no tags\n\n"

    result = described_class.from_string(source)

    expect(result.input_without_tags).to eq('Same as before but no tags')
    expect(result.extracted_tags).to be_nil
  end

  it 'extracts exactly MAX_TAGS_ALLOWED tags' do
    tag = "<a href='https://gnome.org/tags/test'>#test</a>"
    source = "Testing the tag limit\n\n" + (tag * described_class::MAX_TAGS_ALLOWED)

    result = described_class.from_string(source)

    expect(result.input_without_tags).to eq('Testing the tag limit')
    expect(tag_pairs(result).length).to eq(described_class::MAX_TAGS_ALLOWED)
  end

  it 'extracts nothing when there is one tag more than MAX_TAGS_ALLOWED' do
    tag = "<a href='https://gnome.org/tags/test'>#test</a>"
    source = "Testing the tag limit\n\n" + (tag * (described_class::MAX_TAGS_ALLOWED + 1))

    result = described_class.from_string(source)

    expect(result.input_without_tags).to be_nil
    expect(result.extracted_tags).to be_nil
  end
end
