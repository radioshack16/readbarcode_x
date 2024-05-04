#------
# Resample
#------
# K.Hirooka
# 2024/03/31, Sun.
# 2024/05/03, Fri.
#------
require 'complex'
require 'fileutils'

class Array
  #----------------------------------------------------------------------
  # Resample
  # with raised cosine filter
  #----------------------------------------------------------------------
  # self:
  #   1d barcode gray level 8bit signal
  #       0   <---> 255
  #     black <---> white
  #
  # Parameters: shown below
  #
  # return:
  #   resampled array
  #----------------------------------------------------------------------
  def resample_BW_full(resample_pos_a,  # resample position array
                       param_a)         # [roll-off_factor beta, length of single side of pulse]
    sig_a = self
    ovr_n = 10
    #--------------------------------------------------
    # raised cosine pulse
    #--------------------------------------------------
    beta, len_ss = param_a
    puts "beta = %.2f, len_ss = %d" % [beta, len_ss]  if $dmon
    #----------------------------------------
    # sinc(x)
    #----------------------------------------
    n_ss = len_ss * ovr_n
    n = n_ss * 2 + 1
    k_a = (-n_ss..n_ss).to_a    # CAUTION: MINUS .. ZERO .. PLUS
    # x_a = k_a.map{|k| k.to_f/ovr_n}
    dth = Math::PI/ovr_n
    sinc_a = k_a.map{|k|
      th = dth * k
      k==0 ? 1.0 : Math::sin(th)/th
    }
    #----------------------------------------
    # Window
    #----------------------------------------
    # numerator
    numer_a = k_a.map{|k|
      th = dth * k * beta
      Math::cos(th)
    }
    # denominator
    denom_a = k_a.map{|k|
      1.0 - (2.0*beta*(k.to_f/ovr_n))**2
    }
    #------------------------------
    # numerator/denominator
    #------------------------------
    min_th = 1.0/(2**32)    # =:= 2.3e-10
    win_a = k_a.map.with_index{|k, idx|
      if denom_a[idx].abs < min_th
        Math::PI/(4.0)         # PI/4, limit value when denom --> 0.
      else
        numer_a[idx]/denom_a[idx]
      end
    }
    puts "min_th=%.2e" % min_th if $dmon
    #------------------------------
    # sinc(x) * window(x)
    #------------------------------
    raised_cos_a = k_a.map.with_index{|k, idx|
      sinc_a[idx] * win_a[idx]
    }
    #--------------------------------------------------
    # Resample
    # 1) Up-sample
    # 2) Interpolate
    # 3) Down-sample
    #--------------------------------------------------
    # 1) Up-sample
    sig_up_a = Array.new((ovr_n * (sig_a.size-1))+1, 0)
    sig_a.each_with_index{|v, i|
      sig_up_a[i*ovr_n] = v
    }
    puts "ovr_n = %d" % ovr_n if $dmon
    #------------------------------
    # 2) Interpolate with raised-cosine filter
    #   sig_up_a[] * raised_cos_a[]
    sig_up_bl_a = sig_up_a.convolve raised_cos_a
    if $dmon
      pp raised_cos_a[n_ss-1]
      pp raised_cos_a[n_ss]
      pp raised_cos_a[n_ss+1]
      puts "---"
      puts "sig_up_a.size     = %d" % sig_up_a.size
      puts "raised_cos_a.size = %d" % raised_cos_a.size
      puts "sig_up_bl_a.size  = %d" % sig_up_bl_a.size
      puts "---"
    end
    #------------------------------
    # 3) Down-sample
    puts "sample_cnt = %d" % resample_pos_a.size  if $dmon
    sample_a = resample_pos_a.map{|x|
      x_ovr_n = (x * ovr_n).round
      #[x, x_ovr_n]    # DEBUG
      sig_up_bl_a[x_ovr_n]
    }
    if $dmon
      # for monitor
      sig_up_bl_sample_a = Array.new(sig_up_bl_a.size, 0)
      resample_pos_a.each{|x|
        x_ovr_n = (x * ovr_n).round
        sig_up_bl_sample_a[x_ovr_n] = sig_up_bl_a[x_ovr_n]
      }
      # Monitor: mid
      pp resample_pos_a[115, 3]
      pp sample_a[115, 3]
      # Monitor: last part
      len_tmp = resample_pos_a.size
      puts "Monitor: resample first part"
      pp resample_pos_a[0, 3]
      pp sample_a[0, 3]
      puts "Monitor: resample last part"
      puts "len = %d" % len_tmp
      pp resample_pos_a[len_tmp-3, 3]
      pp sample_a[len_tmp-3, 3]
    end
    sample_a
  end

end
