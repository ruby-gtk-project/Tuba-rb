# frozen_string_literal: true

require_relative '../lib/utils_blurhash'

# Ported from upstream's tests/Blurhash.test.vala.
RSpec.describe Utils::Blurhash do
  describe '.Base83.decode' do
    {
      'tuba' => 31_837_176,
      '0m0R1' => 27_448_018,
      'P7btDt@Pap!szZkkEoSnK5e%cg!QC4' => 0,
      'VPmm5Ft%!9tG5hC7J^vwHToZoFJVKLDgY78kE%dPaiLB^^rv^P9f6UwR*p@c!UB' => 0,
      'L00000fQfQfQfQfQfQfQfQfQfQfQ' => -718_366_762,
      'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.' => 934_061_677,
      'L6PZfSjE.AyE_3t7t7R**0o#DgR4' => -1_746_869_106,
      'LKO2:N%2Tw=w]~RBVZRi};RPxuwH' => -1_074_644_314,
      'LEHLk~WB2yk8pyo0adR*.7kCMdnj' => 1_224_798_277
    }.each do |encoded, decoded|
      it "test_base83_decode: decodes #{encoded.inspect} to #{decoded}" do
        expect(Utils::Blurhash::Base83.decode(encoded)).to eq(decoded)
      end
    end
  end

  describe '.valid_blurhash?' do
    {
      'invalidblurhash' => false,
      'tuba' => false,
      '6chars' => false,
      'L00000fQfQfQfQfQfQfQfQfQfQfQ' => true,
      'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.' => true,
      'L6PZfSjE.AyE_3t7t7R**0o#DgR4' => true,
      'LKO2:N%2Tw=w]~RBVZRi};RPxuwH' => true,
      'LEHLk~WB2yk8pyo0adR*.7kCMdnj' => true,
      'LEHLk~WB2yk8pyo0adR*.7kCMdnj.' => false
    }.each do |blurhash, valid|
      it "test_blurhash_validity: #{blurhash.inspect} is #{valid ? 'valid' : 'invalid'}" do
        expect(described_class.valid_blurhash?(blurhash)).to eq(valid)
      end
    end
  end

  describe '.decode_dimensions' do
    {
      'L00000fQfQfQfQfQfQfQfQfQfQfQ' => [4, 3],
      'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.' => [4, 3],
      'L6PZfSjE.AyE_3t7t7R**0o#DgR4' => [4, 3],
      'LKO2:N%2Tw=w]~RBVZRi};RPxuwH' => [4, 3],
      'LEHLk~WB2yk8pyo0adR*.7kCMdnj' => [4, 3],
      'oHF5]+Yk^6#M9wKS@-5b,1J5O[V=@[or[k6.O[TL};FxngOZE3NgjMFxS#OtcXnzj]OYNeR:JCs9' => [6, 6],
      'o6PZfSi_.AyE8^m+_3t7t7R*WBs,*0o#DgR4.Tt,_3R*D%xt%MIpMcV@%itSI9R5Iot7-:IoM{%L' => [6, 6],
      'oKN]Rv%2Tw=wR6cE]~RBVZRip0W9};RPxuwH%3s8tLOtxZ%gixtQI.ENa0NZIVt6%1j^M_bcRPX9' => [6, 6],
      'oEHLk~WB2yk8$Nxupyo0adR*=ss:.7kCMdnjx]S2S#M|%1%2ENRiSis.slNHW:WBogaekBW;ofo0' => [6, 6]
    }.each do |blurhash, (num_x, num_y)|
      it "test_blurhash_ratio: #{blurhash.inspect} is #{num_x}x#{num_y}" do
        _size_flag, res_x, res_y, = described_class.decode_dimensions(blurhash)

        expect(res_x).to eq(num_x)
        expect(res_y).to eq(num_y)
      end
    end
  end

  describe '.decode_to_data' do
    it 'returns nil for an invalid blurhash' do
      expect(described_class.decode_to_data('invalid', 10, 10)).to be_nil
    end

    {
      'L00000fQfQfQfQfQfQfQfQfQfQfQ' => [0, 0, 0, 255],
      'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.' => [172, 120, 180, 255],
      'L6PZfSjE.AyE_3t7t7R**0o#DgR4' => [228, 227, 224, 255],
      'LKO2:N%2Tw=w]~RBVZRi};RPxuwH' => [237, 188, 167, 255],
      'LEHLk~WB2yk8pyo0adR*.7kCMdnj' => [153, 170, 176, 255]
    }.each do |blurhash, pixel|
      it "test_blurhash_data: decodes #{blurhash.inspect} to the pixel at byte 8" do
        data = described_class.decode_to_data(blurhash, 10, 10)

        expect(data).not_to be_nil
        expect(data[8..11]).to eq(pixel)
      end
    end
  end
end
