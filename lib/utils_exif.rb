# frozen_string_literal: true

require 'uri'
require 'gexiv2'

# Utils::Exif pulls accessibility alt text out of an image's own metadata, so
# an attached photo can arrive in the composer with its alt text already
# filled in, instead of making every upload start from a blank field.
#
# Ported from upstream's src/Utils/Exif.vala. Upstream also keeps a
# `#else` branch for a GExiv2 older than 0.16, calling the `try_`-prefixed
# methods instead; the nixpkgs attr this port's flake builds against is
# gexiv2_0_16, so only the `GEXIV2_0_16` branch below applies, and there is no
# `try_` fallback.
module Utils
  module Exif
    # Upstream's ALT_KEYS, checked in this order; the first tag that is
    # present and non-empty wins.
    ALT_KEYS = [
      'Xmp.iptc.AltTextAccessibility',
      'Xmp.dc.description',
      'Iptc.Application2.Caption',
      'Exif.Image.ImageDescription',
      'Exif.Photo.UserComment',
      'Xmp.acdsee.notes',
      'Exif.Image.XPComment',
    ].freeze

    # Upstream's Utils.Exif.extract_alt_text: opens the file at `path` (a
    # plain path or a "file://" URI) and returns the first alt-text tag it
    # finds, or nil if the file has none or cannot be read.
    def self.extract_alt_text(path)
      metadata = GExiv2::Metadata.new

      if path.start_with?('file://')
        metadata.open_path(URI.decode_www_form_component(path.delete_prefix('file://')))
      else
        metadata.open_path(path)
      end

      extract_alt_text_from_metadata(metadata)
    rescue => e
      warn "Error while extracting alt text: #{e.message}"
      nil
    end

    # Upstream's Utils.Exif.extract_alt_text_from_metadata.
    def self.extract_alt_text_from_metadata(metadata)
      tag = ALT_KEYS.find { |candidate| present_tag?(metadata, candidate) }

      if tag.nil?
        nil
      else
        strip_lang_prefix(metadata.get_tag_interpreted_string(tag))
      end
    end

    def self.present_tag?(metadata, tag)
      if metadata.has_tag?(tag)
        alt = metadata.get_tag_interpreted_string(tag)
        !alt.nil? && !alt.empty?
      else
        false
      end
    end

    def self.strip_lang_prefix(text)
      if text.start_with?('lang="x-default" ')
        text.delete_prefix('lang="x-default" ')
      elsif text.start_with?('lang="en" ')
        text.delete_prefix('lang="en" ')
      else
        text
      end
    end
  end
end
