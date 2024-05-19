#------
# Clock extraction
#------
# K.Hirooka
# 2024/03/17, Sun.
# 2024/05/03, Fri.
#------
require 'complex'
require 'fileutils'

class Array
  #----------------------------------------------------------------------
  # Search next rising edge index
  #----------------------------------------------------------------------
  # input:
  #   near-sinusoidal signal
  # Return:
  #   rising edge position index,
  #   where the interval starting from the index has a negative value at the beginning
  #   and zero or positive at the end.
  def next_rise_edge_index(idx_start, idx_max)
    a = self
    #------------------------
    # Search negative
    k = idx_start
    return nil if k > idx_max
    while !(a[k] < 0)
      k+=1
      return nil if k > idx_max
    end
    k+=1
    return nil if k > idx_max
    #------------------------
    # Search zero or positive
    while !(a[k] >= 0)
      k+=1
      return nil if k > idx_max
    end
    ret_k = k-1
    ret_k
  end

  #----------------------------------------------------------------------
  # Convert clock signal array to rising edge position index array
  #----------------------------------------------------------------------
  # input:
  #   near-sinusoidal signal
  # Return:
  #   rising edge position index array,
  #   where the potision gives negative value and the next right position zero or positive.
  def to_rise_edge_index_a
    clk_a = self
    len = clk_a.size
    k=0
    ret_a = []
    while k < (len-1)
      rise_pos = clk_a.next_rise_edge_index(k, len-1)
      if rise_pos == nil
        break
      end
      ret_a << rise_pos
      k = rise_pos + 1
    end
    ret_a
  end

  #----------------------------------------------------------------------
  # Convert rising edge position index to zero-crossing float value array
  #----------------------------------------------------------------------
  # input:
  #   [clk_sig_a, rise_edge_index_a]
  # Return:
  #   rising zero-crossing float array
  def to_zero_cross_a
    clk_sig_a, rise_edge_index_a = self
    sig_len = clk_sig_a.size
    edge_cnt = rise_edge_index_a.size
    puts "sig_len=%d, edge_cnt=%d" % [sig_len, edge_cnt]  if $dmon
    (0..(edge_cnt-1)).to_a.map{|k|
      p = rise_edge_index_a[k]
      x1, y1 = [p,    clk_sig_a[p]  ]
      x2, y2 = [p+1,  clk_sig_a[p+1]]
      x0 = (y2*x1 - y1*x2)/(y2-y1)  # zero cross point. Assume: y1<0, y2>=0
      # puts "k=%d, p=%d, (x1, y1), (x2, y2) = (%d, %f), (%d, %f), x0=%f" % [k, p, x1, y1, x2, y2, x0]
    }
  end

  #----------------------------------------------------------------------
  # Clock signal, cos wave
  #----------------------------------------------------------------------
  # input:
  #   [freq, amp, ph_ofst, sig_len, over_n]
  def to_clock_sig_a
    freq, amp, ph_ofst, sig_len, over_n = self
    # DEBUG: amp, ph_ofst = 1.0, 0.0 # TEST
    len_total = sig_len*over_n
    d_phase = 2.0*Math::PI*freq/len_total.to_f
    (0..(len_total-1)).to_a.map{|k|
      amp * Math::cos(d_phase*k + ph_ofst)
    }
  end

  #----------------------------------------------------------------------
  # Partial-freq DFT
  #----------------------------------------------------------------------
  # input:  real array
  # return: complex array of DFT components for specified frequency
  #     index     :   freq
  #       0       --> f_ana_min
  #       (len-1) --> f_ana_max
  def dft(f_ana_min, f_ana_max)
    in_a = self
    len = self.size
    f_nyq = len/2
    w1 = 2.0*Math::PI/len
    (f_ana_min..f_ana_max).to_a.map{|fn|
      wn = -w1*fn
      revrot_ca = (0..len-1).to_a.map{|k|
        Complex.polar(1, wn*k)
      }
      (in_a.inner_product revrot_ca)/len
    }
  end

  #----------------------------------------------------------------------
  # self: 1d barcode gray level 8bit signal
  #           0/black <---> 255/ white
  # return:
  #   e.g.
  #     for neighbor_k = 1,
  #     [power-max-frequency, [dft_a[maxpos], dft_a[maxpos+1], dft_a[maxpos-1]].
  #   呼び出し側ではdft_a配列に次のようにアクセスできる:
  #     ret_a[-1]:  f_max-1
  #     ret_a[ 0]:  f_max
  #     ret_a[ 1]:  f_max+1
  #----------------------------------------------------------------------
  def to_clock_compo_a(neighbor_k)
    in_sig_a = self
    len = in_sig_a.size
    #----------------------------------------
    # edge, abs
    #----------------------------------------
    edge_a = in_sig_a.convolve([+1, 0, -1])
    edge_abs_a = edge_a.to_abs_a
    #----------------------------------------
    # Freq analysis
    #----------------------------------------
    puts "input signal length = %d, at %s" % [len, __method__]  if $dmon
    if (len % 2)!=0
      puts "Error: input signal length = %d, not even, unexpected, at %s" % [len, __method__];exit
    end
    f_nyq = len/2
    f_ana_min = (f_nyq * 0.50).to_i    # Modify later
    f_ana_max = (f_nyq * 0.80).to_i    # Modify later
    puts "freq: nyq, ana_min, ana_max = %d, %d, %d" % [f_nyq, f_ana_min, f_ana_max] if $dmon
    dft_a = edge_abs_a.dft(f_ana_min, f_ana_max)  # Use FFT later
    power_a = dft_a.to_abs2_a
    power_a = power_a.normalize(100.0)
    #------------------------------
    # Monitor
    #------------------------------
    if $dmon
      pp dft_a[0, 3]
      pp power_a[0, 3]
    end
    pwr_size = power_a.size
    freq_a = (f_ana_min..f_ana_max).to_a
    #----------------------------------------
    # Pick clock components,
    # taking the maximum and its neighbors
    #----------------------------------------
    max_v = power_a.max
    f_max_idx = power_a.index(max_v)
    f_max = f_max_idx + f_ana_min
    # The power-maximum and its neighboring components
    compo_n = 2*neighbor_k + 1
    ret_a = [f_max,
              (0..(compo_n-1)).to_a.map{|k|
                ofst = (k <= neighbor_k) ? k : (k - compo_n)
                dft_a[f_max_idx + ofst]
              }
            ]
    if $dmon
      puts  "dft_a[f_max_idx-1, 3]:"
      pp dft_a[f_max_idx-1, 3]
      puts "power_a: max: value, freq = %d, %d" % [max_v, f_max]
    end
    ret_a
  end

  #--------------------------------------------------
  # Extract clock signal from a barcode signal
  #--------------------------------------------------
  # self:   barcode signal array
  # return: oversampled clock signal
  def extract_clock_sig(over_n) # oversampling rate: 4 typ
    bcode_sig_a = self
    sig_len     = bcode_sig_a.size
    #------------------------------------------------------------
    # Extract clock components
    # input:  No-EQ signal,
    #         which results in slightly smaller side-components
    #         than using EQ-signal.
    #------------------------------------------------------------
    f_max, dft_clock_compo_a = bcode_sig_a.to_clock_compo_a(1)   # neighbor_k = 1
    sample_interval = bcode_sig_a.size / f_max.to_f
    if $dmon
      puts "f_max = %d" % f_max
      puts "sample_interval = %.2f" % sample_interval
      puts "dft_clock_compo_a = "
      pp dft_clock_compo_a
    end
    #--------------------------------------------------
    # Monitor clock_component array
    #--------------------------------------------------
    if $dmon
      [-1, 0, +1].each{|k|
        f = f_max + k
        amp, ph = dft_clock_compo_a[k].polar
        puts "freq=%d, amp, ph = %f, %f" % [f, amp, ph]
      }
    end
    #--------------------------------------------------
    # Clock components signal
    #--------------------------------------------------
    clk_ovr_sig_len = sig_len*over_n
    clk_sig_aa = [[], [], []]
    [-1, 0, +1].each{|k|
      # Caution: oversampled
      clk_sig_aa[k] = [f_max+k, dft_clock_compo_a[k].polar, sig_len, over_n].flatten.to_clock_sig_a
    }
    if $dmon
      pp clk_sig_aa[ 0][0, 8]
      pp clk_sig_aa[-1][0, 8]
      pp clk_sig_aa[ 1][0, 8]
    end
    #------------------------------------------------------------
    # Sum of clock components
    #------------------------------------------------------------
    # Caution: oversampled
    clk_sig_a = (0..(clk_ovr_sig_len-1)).to_a.map{|k|
      clk_sig_aa[-1][k] + clk_sig_aa[0][k] + clk_sig_aa[1][k]   # 2nd-max, max, 3rd-max(negligible)
    }
    clk_sig_a
  end

  #--------------------------------------------------
  # Extract sample position from the input clock signal
  #--------------------------------------------------
  # self:   oversampled clock signal
  # return: sample position array
  def to_sample_pos_a(over_n)     # oversampling rate: 4 typ
    clk_sig_over_n_a = self
    #------------------------------------------------------------
    # Extract clock rising edge position as index
    #------------------------------------------------------------
    # Caution: clock siganal is oversampled
    rise_edge_index_over_n_a = clk_sig_over_n_a.to_rise_edge_index_a
    #------------------------------------------------------------
    # Extract clock rising zero-crossing point
    #------------------------------------------------------------
    rise_edge_zero_cross_over_n_a = [clk_sig_over_n_a, rise_edge_index_over_n_a].to_zero_cross_a
    # Scale the position to the original by oversample rate
    rise_edge_zero_cross_a = rise_edge_zero_cross_over_n_a.map{|x| x/over_n}
    if $dmon
      pp rise_edge_zero_cross_over_n_a[0, 3]
      pp rise_edge_zero_cross_over_n_a[-3, 3]
      pp rise_edge_zero_cross_a[0, 3]
      pp rise_edge_zero_cross_a[-3, 3]
    end
    #------------------------------------------------------------
    # Adjust the rising zero-crossing position to sampling one
    #------------------------------------------------------------
    # Sampling position is 1/4-period left of the rising edge of the clock
    resample_pos_a = (0..(rise_edge_zero_cross_a.size-2)).to_a.map{|k|
      (rise_edge_zero_cross_a[k] + 3*rise_edge_zero_cross_a[k+1])/4
    }
    if $dmon
      puts "resample_pos_a"
      pp resample_pos_a[0, 3]
      pp resample_pos_a[-3, 3]
    end
      #------------------------------
      # Save sig into text file
      #------------------------------
      resample_pos_a.join("\n").to_file("#{$tmp_dir}/T600_resample_pos_a.txt")
    resample_pos_a
  end

end
