#! ruby -EUTF-8
# -*- mode:ruby; coding:utf-8 -*-

# Kazuyuki Hirooka, 2024/05/04, Sat.

require 'pp'
require 'fileutils'

require './global_defs.rb'

require './ruby_lib/nsa_extend.rb'
require './ruby_lib/read_receipt_png.rb'
require './ruby_lib/extract_barcode_sig.rb'
require './ruby_lib/clock_signal.rb'
require './ruby_lib/sig_process.rb'
require './ruby_lib/resample.rb'
require './ruby_lib/decode_nw7_9bit.rb'

def help
  puts "Usage: readbarcode_nw7.rb PNG_file_path"
  puts "e.g.: readbarcode_nw7.rb foo.png"
end

$dmon = false
#================================================================================
# Main
#================================================================================
argc = ARGV.size
if argc!=1
  help
  exit
end
src_path = ARGV[0]

file_ext_s = File.extname(src_path)
if file_ext_s.upcase!=".PNG"
  puts "Error: file extension = %s, unexpected. Only support PNG file." % file_ext_s
  exit
end
if !src_path.file_exist?
  puts "Error: file not found: %s" % src_path
  exit
end

#--------------------------------------------------------------------------------
# 1. Read the source PNG file
# 2. Extract barcode signal from the source PNG Image file
# 3. Extract clock signal from the barcode signal
# 4. Bandwidth-limit the barcode signal
# 5. Resample the bandwidth-limit barcode signal at optimal sampling point with
#    the clock signal
# 6. Detect sync-patterns at left and right on the resampled signal
# 7. Slice codes between the syncs
# 8. Decode the codes into characters, selecting minimum Euclidean distance codes
#--------------------------------------------------------------------------------

$tmp_dir = "tmp_result"
$tmp_dir.mkdir_p
clk_over_n = 4

img_aa                  = src_path.read_png_to_img_aa
bcode_sig_a             = img_aa.extract_barcode_sig
clk_sig_over_n_a        = bcode_sig_a.extract_clock_sig(clk_over_n)
resample_pos_a          = clk_sig_over_n_a.to_sample_pos_a(clk_over_n)
eq_tap_a                = [1, 2, 1].sum_normalize   # LPF as a bandwidth-limit filter. TENTATIVE
bcode_sig_eq_a          = bcode_sig_a.convolve eq_tap_a
bcode_resampled_a       = bcode_sig_eq_a.resample_BW_full(resample_pos_a, [0.5, 3])   # oversampled inside
bcode_resampled_dcbal_a = bcode_resampled_a.dc_balance
sync_pos_left, sync_pos_right = bcode_resampled_dcbal_a.sync_pos_left_right(
                                                        $barcode_NW7_CANDO_sync_left,
                                                        $barcode_NW7_CANDO_sync_right)
code_aa = bcode_resampled_dcbal_a.slice_code(sync_pos_left + $barcode_NW7_CANDO_sync_left.size + 1,
                                             sync_pos_right - 1)
decoded_char_a = code_aa.map{|a| a.nw7_9bit_code_to_char}
decoded_s = [$CANDO_sync_char, decoded_char_a, $CANDO_sync_char].flatten.join
puts decoded_s
# End
