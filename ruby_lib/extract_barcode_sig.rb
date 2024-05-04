require 'pp'
require 'fileutils'
require './ruby_lib/nsa_extend.rb'

class Array
  def to_diff_a
    a = self
    n = a.size
    (1..(n-2)).to_a.map{|k|
      a[k+1] - a[k-1]
    }
  end

  #----------------------------------------
  # 1D convolution
  #----------------------------------------
  # size will be kept.
  # boundary parts are set zero.
  #----------------------------------------
  def convolve coef_a
    tap_n = coef_a.size
    puts "tap_n = %d" % tap_n if $dmon
    if tap_n.even?
      puts "Error: coef_a size is %d, even, not supported, at %s" % [tap_n, __method__]
      exit
    end
    shrink_n = tap_n/2  # e.g.: 7 ==> 3
    puts "shrink_n = %d" % shrink_n if $dmon
    v_a = self
    sig_n = v_a.size
    out_a = (shrink_n..(sig_n-1-shrink_n)).to_a.map{|k|
      v_a[k-shrink_n, tap_n].inner_product(coef_a)
    }
    # fill zeros at the beginning and the ending
    zero_a = Array.new(shrink_n, 0)
    out_a = zero_a + out_a + zero_a
    out_a
  end

  #------------------------------------------------------------
  # Extract barcode signal from an image data
  #------------------------------------------------------------
  # self: image array of array
  def extract_barcode_sig
    img_aa = self
    #------------------------------------------------------------
    # Array of edgx_index_along_y
    # as a preparation for searching barcode area
    #------------------------------------------------------------
    edgx_index_along_y_a= img_aa.map{|row_a|
      row_a.to_diff_a.to_abs_a.sum
    }
    edgx_index_along_y_a.join(',').to_file("tmp_result/T001_edgx_index_along_y_a.csv")

    #------------------------------------------------------------
    # LPF(Moving-Average-101) edgx_index_along_y_a,
    # to make the barcode area peaky
    #------------------------------------------------------------
    puts "height = %d" % edgx_index_along_y_a.size  if $dmon
    ma_tap_a = Array.new(101, 1)
    edgx_along_y_lpf_a = edgx_index_along_y_a.convolve(ma_tap_a)
    puts "height = %d" % edgx_along_y_lpf_a.size    if $dmon
    edgx_along_y_lpf_a.join(',').to_file("tmp_result/T002_edgx_along_y_lpf_a.csv")

    #------------------------------------------------------------
    # Search max position for barcode-reading
    #------------------------------------------------------------
    max_v     = edgx_along_y_lpf_a.max
    max_pos_y = edgx_along_y_lpf_a.index(max_v)
    puts "max_v = %d, at y = %d, at %s" % [max_v, max_pos_y, __method__] if $dmon
    bcode_pos_y = max_pos_y

    #------------------------------------------------------------
    # Get barcode line signal
    #------------------------------------------------------------
    if not (0 < bcode_pos_y && bcode_pos_y < (img_aa.size-1))
      puts "Error: bcode_pos_y = %d, unexpected."; exit
    end
    width = img_aa[0].size
    bcode_sig_a = (0..(width-1)).to_a.map{|k|
      (img_aa[bcode_pos_y-1][k] +       # Moving Average of 3
       img_aa[bcode_pos_y  ][k] +
       img_aa[bcode_pos_y+1][k]) / 3
    }
    sig_len =  bcode_sig_a.size
    # Adjust bcode_sig_a size to be EVEN for clock extraction later
    if sig_len%2==1
      bcode_sig_a.delete_at(0)
      sig_len =  bcode_sig_a.size
    end
    bcode_sig_a.join(',').to_file("tmp_result/T003_bcode_sig_a.csv")
    bcode_sig_a
  end

end
