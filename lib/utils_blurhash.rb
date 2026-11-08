# frozen_string_literal: true

# Utils::Blurhash decodes a Blurhash string (the short placeholder-image
# code Mastodon sends alongside media attachments) into pixel data or a
# ready-to-display GdkPixbuf.
#
# Ported from upstream's src/Utils/Blurhash.vala, itself adapted from
# https://github.com/woltapp/blurhash and
# https://github.com/mad-gooze/fast-blurhash.
module Utils
  class Blurhash
    AverageColor = Struct.new(:r, :g, :b)

    # Decodes a Base83-encoded chunk of a blurhash into an integer.
    #
    # Ported from upstream's Blurhash.Base83.decode. Upstream accumulates
    # the result in a 32-bit C `int`, deliberately relying on unsigned
    # multiply-and-wrap on overflow (its own test table expects negative
    # results for long strings), so this port reproduces that wraparound
    # by hand: Ruby integers never overflow on their own.
    class Base83
      CHARACTERS = (
        ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a +
        %w[# $ % * + , - . : ; = ? @ [ ] ^ _ { | } ~]
      ).freeze

      UINT32_MASK = 0xFFFFFFFF

      class << self
        def decode(value)
          res = 0
          value.each_char do |character|
            index = CHARACTERS.index(character)
            if index.nil?
              res = 0
              break
            else
              res = ((res & UINT32_MASK) * 83 + index) & UINT32_MASK
            end
          end

          to_int32(res)
        end

        private

          def to_int32(uint32_value)
            uint32_value >= 0x80000000 ? uint32_value - 0x100000000 : uint32_value
          end
      end
    end

    class << self
      # Checks that `blurhash` is well-formed and, if so, returns its
      # [size_flag, num_x, num_y, size] tuple; otherwise returns nil.
      #
      # Ported from upstream's `is_valid_blurhash`, which returns the same
      # four values through `out` parameters alongside a boolean.
      def decode_dimensions(blurhash)
        hash_length = blurhash.length
        return nil if hash_length < 6

        size_flag = decode_partial(blurhash, 0, 1)
        num_y = (size_flag / 9) + 1
        num_x = (size_flag % 9) + 1
        size = num_x * num_y

        return nil unless hash_length == 4 + 2 * size

        [size_flag, num_x, num_y, size]
      end

      def valid_blurhash?(blurhash)
        !decode_dimensions(blurhash).nil?
      end

      def blurhash_average_color(blurhash)
        value = decode_partial(blurhash, 2, 6)
        AverageColor.new(value >> 16, (value >> 8) & 255, value & 255)
      end

      # Decodes `blurhash` into raw RGB(A) pixel bytes, `width` x `height`,
      # row-major, top to bottom. Returns nil for an invalid blurhash.
      #
      # Ported from upstream's `decode_to_data`.
      def decode_to_data(blurhash, width, height, punch: 1, has_alpha: true)
        dimensions = decode_dimensions(blurhash)
        return nil if dimensions.nil?

        _size_flag, num_x, num_y, size = dimensions
        punch = 1 if punch < 1

        bytes_per_row = width * (has_alpha ? 4 : 3)
        data = Array.new(bytes_per_row * height, 0)

        maximum_value = (decode_partial(blurhash, 1, 2) + 1) / 166.0
        colors = Array.new(size * 3, 0.0)

        average_color = blurhash_average_color(blurhash)
        colors[0] = srgb_to_linear(average_color.r)
        colors[1] = srgb_to_linear(average_color.g)
        colors[2] = srgb_to_linear(average_color.b)

        (1...size).each do |i|
          value = decode_partial(blurhash, 4 + (i * 2), 6 + (i * 2))
          r, g, b = decode_ac(value, maximum_value * punch)
          colors[i * 3] = r
          colors[(i * 3) + 1] = g
          colors[(i * 3) + 2] = b
        end

        (0...height).each do |y|
          yh = (Math::PI * y) / height
          (0...width).each do |x|
            r = 0.0
            g = 0.0
            b = 0.0
            xw = (Math::PI * x) / width

            (0...num_y).each do |j|
              basis_y = Math.cos(yh * j)
              (0...num_x).each do |i|
                basis = Math.cos(xw * i) * basis_y

                color_index = (i + (j * num_x)) * 3
                r += colors[color_index] * basis
                g += colors[color_index + 1] * basis
                b += colors[color_index + 2] * basis
              end
            end

            pixel_index = (4 * x) + (y * bytes_per_row)
            data[pixel_index] = linear_to_srgb(r)
            data[pixel_index + 1] = linear_to_srgb(g)
            data[pixel_index + 2] = linear_to_srgb(b)
            data[pixel_index + 3] = 255 if has_alpha
          end
        end

        data
      end

      # Ported from upstream's `blurhash_to_pixbuf`, including its literal
      # rowstride of `4 * height` rather than `4 * width` — upstream's own
      # arithmetic, reproduced rather than silently "fixed".
      def blurhash_to_pixbuf(blurhash, width, height)
        data = decode_to_data(blurhash, width, height)
        return nil if data.nil?

        # Pulled in lazily: every other method here is pure arithmetic, and
        # loading gtk4 just to decode a blurhash's bytes would drag the
        # whole toolkit (and its typelib dependencies) into contexts, like
        # the plain `rspec` runner, that never touch a widget.
        require 'gtk4'

        GdkPixbuf::Pixbuf.new(
          data: data.pack('C*'),
          colorspace: :rgb,
          has_alpha: true,
          bits_per_sample: 8,
          width: width,
          height: height,
          rowstride: 4 * height,
        )
      end

      private

        # Decodes a Base83-encoded slice of `str`, matching upstream's
        # `decode_partial`: `str.slice(start, end)` in Vala takes the
        # characters from `start` up to (excluding) `end`, exactly like
        # Ruby's `str[start...end]`.
        def decode_partial(str, start, finish)
          return 0 if start > finish

          finish = str.length if finish >= str.length
          Base83.decode(str[start...finish])
        end

        def linear_to_srgb(value)
          v = value.clamp(0.0, 1.0)
          if v <= 0.0031308
            ((v * 12.92 * 255) + 0.5).to_i
          else
            (((1.055 * (v**(1 / 2.4))) - 0.055) * 255 + 0.5).to_i
          end
        end

        def srgb_to_linear(value)
          v = value / 255.0
          if v <= 0.04045
            v / 12.92
          else
            (((v + 0.055) / 1.055)**2.4)
          end
        end

        def sign_pow(value, exponent)
          sign = value.negative? ? -1 : 1
          sign * (value.abs**exponent)
        end

        def decode_ac(value, maximum_value)
          quant_r = value / 361
          quant_g = (value / 19) % 19
          quant_b = value % 19

          [
            sign_pow((quant_r - 9) / 9.0, 2.0) * maximum_value,
            sign_pow((quant_g - 9) / 9.0, 2.0) * maximum_value,
            sign_pow((quant_b - 9) / 9.0, 2.0) * maximum_value
          ]
        end
    end
  end
end
