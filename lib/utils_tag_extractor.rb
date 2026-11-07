# frozen_string_literal: true

# Utils::TagExtractor pulls the trailing paragraph of hashtag links off a
# composed status's Pango markup, so the composer can show them as removable
# chips instead of inline text.
#
# Ported from upstream's src/Utils/TagExtractor.vala. A result only comes
# back when the input's last paragraph (the text after its final blank line)
# consists of nothing but consecutive `<a href='...'>#tag</a>` links, up to
# MAX_TAGS_ALLOWED of them; anything else in that paragraph, or more tags than
# the limit, yields no extraction at all (both fields nil), matching
# upstream's `Result { null, null }`.
module Utils
  class TagExtractor
    MAX_TAGS_ALLOWED = 20

    PANGO_URI_REGEX = %r{<a href='(?<href>http[^']+)'>#(?<tag>[^<]+)</a>}i

    Tag = Struct.new(:tag, :link)
    Result = Struct.new(:input_without_tags, :extracted_tags)

    NO_RESULT = Result.new(nil, nil)

    class << self
      def from_string(input)
        last_paragraph_begin = input.rindex("\n\n")

        if last_paragraph_begin.nil?
          NO_RESULT
        else
          extract_from_last_paragraph(input, last_paragraph_begin)
        end
      end

      private

      def extract_from_last_paragraph(input, last_paragraph_begin)
        last_paragraph = input[last_paragraph_begin..]

        if last_paragraph.strip.include?("\n")
          NO_RESULT
        else
          build_result(input, last_paragraph_begin, last_paragraph)
        end
      end

      def build_result(input, last_paragraph_begin, last_paragraph)
        extracted_tags = []
        cleaned_up_paragraph = last_paragraph.gsub(PANGO_URI_REGEX) do
          extracted_tags << Tag.new(Regexp.last_match(:tag), Regexp.last_match(:href))
          ''
        end.strip

        if cleaned_up_paragraph != '' || extracted_tags.length > MAX_TAGS_ALLOWED
          NO_RESULT
        else
          Result.new(input[0...last_paragraph_begin], extracted_tags.empty? ? nil : extracted_tags)
        end
      end
    end
  end
end
