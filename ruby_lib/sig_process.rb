require 'pp'

class Array
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
  # DC balance
  #------------------------------------------------------------
  def dc_balance
    a = self
    v_dc = a.avg
    dcbal_a = a.map{|x| x - v_dc}
    if $dmon
      pp a.min
      pp a.max
      puts "v_dc = %.2f" % v_dc
      pp a[100,5]
      pp dcbal_a[100,5]
      pp dcbal_a.avg
    end
    dcbal_a
  end

  #------------------------------------------------------------
  # Search sync pattern by correlation
  #------------------------------------------------------------
  # self:       in_a      # should be DC balanced
  # ss_range:                 sync search range
  # return: matched position
  def sync_pos(sync_pat_a,  pos_sta_raw, ss_range)
    in_a = self
    in_len = in_a.size
    pos_sta = (pos_sta_raw < 0) ? (in_len + pos_sta_raw) : pos_sta_raw
    pos_end = pos_sta + ss_range - 1
    if $dmon
      puts "in_a.size     = %d" % in_a.size
      puts "pos_sta_raw   = %d, ss_range = %d" % [pos_sta_raw, ss_range]
      puts "pos_sta, _end = %d, %d" % [pos_sta, pos_end]
    end
    sync_len = sync_pat_a.size
    corr_a = (pos_sta..pos_end).to_a.map{|k|
      in_a[k, sync_len].inner_product sync_pat_a
    }
    max_v, max_pos_raw = corr_a.each_with_index.max
    max_pos = pos_sta + max_pos_raw
    if $dmon
      puts "sync_pat_a: "
      pp    sync_pat_a
      puts "sync_pat_a.size = %d" % sync_pat_a.size
      puts "corr_a.size     = %d" % corr_a.size
      puts "max_val, pos = %.2f, %d" % [max_v, max_pos]
    end
    max_pos
  end

  #------------------------------------------------------------
  # Detect sync-patterns, left and right
  #------------------------------------------------------------
  # self:   resampled DC-balanced array
  # return: sync position left and right
  def sync_pos_left_right(sync_pat_left, sync_pat_right)
    dcbal_a = self
    sync_len = sync_pat_left.size
    if sync_pat_right.size != sync_len
      puts "Error: sync pattern size differ, unexpected at %s" % __method__
    end
    ss_range = dcbal_a.size/4 - sync_len
    # Search sync in the left quater
    sync_pos_left   = dcbal_a.sync_pos(sync_pat_left, 0,                     ss_range)
    # Search sync in the right quater
    sync_pos_right  = dcbal_a.sync_pos(sync_pat_right, -sync_len-ss_range+1, ss_range)
    [sync_pos_left, sync_pos_right]
  end

  #------------------------------------------------------------
  # Slice into codes between left and right syncs
  #------------------------------------------------------------
  # self:       resampled DC-balanced array
  # parameters: sync position left and right
  def slice_code(start_pos, end_pos)
    sig_a = self
    body_bit_len    = end_pos - start_pos + 1 # Includes a gap on the the right end.
    code_bit_len    = 9                 # Cando: The body contains 9bit-code characters only.
    code_bit_period = code_bit_len + 1  # +1: Gap between codes
    code_cnt = body_bit_len/code_bit_period
    if (body_bit_len % code_bit_period)!=0
      puts "Error: body_bit_len = %d, unexpected body_bit_len. Must be a multiple of %d." %
            [body_bit_len, code_bit_period]
      exit
    end
    code_aa = (0...code_cnt).to_a.map{|k|
      pos = start_pos + (k*code_bit_period)
      sig_a[pos, code_bit_len]
    }
    code_aa
  end

end
