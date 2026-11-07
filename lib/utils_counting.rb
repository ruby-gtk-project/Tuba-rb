# frozen_string_literal: true

# Utils::Counting counts user-perceived characters (grapheme clusters, so a
# flag or a family emoji counts once) and strips the server part off of
# locally-known mentions for the composer's running character count.
#
# Ported from upstream's src/Utils/Counting.vala. Upstream counts with ICU's
# character BreakIterator; this port uses Ruby's own extended-grapheme-cluster
# iteration (String#each_grapheme_cluster), which agrees with ICU for plain
# text and multi-codepoint emoji but is not locale-tailored, so it does not
# special-case the small set of scripts (e.g. Devanagari conjuncts) where ICU's
# per-locale rules merge clusters that UAX #29 alone keeps separate.
module Utils
  class Counting
    MENTION_REGEX = /(^|[^\/\w])@(([a-z0-9_]+)@[a-z0-9.-]+[a-z0-9]+)/i

    class << self
      def chars(content, _language = 'en')
        content.each_grapheme_cluster.count
      end

      def replace_mentions(content)
        content.gsub(MENTION_REGEX) { "#{Regexp.last_match(1)}@#{Regexp.last_match(3)}" }
      end
    end
  end
end
