require 'pp'
require 'fileutils'
require 'chunky_png'
# Install:
#   >gem install chunky_png
# Doc:
#   https://rubydoc.info/gems/chunky_png/ChunkyPNG/Canvas/PNGEncoding#to_datastream-instance_method

charset = "UTF-8"

class Integer
  # input: 24bit: RGB   # Alpha-blend NOT included.
  def rgb24bit_to_gray8bit
    r =  self >> 16
    g = (self >>  8) & 0xFF
    b =  self        & 0xFF
    (r+g+b)/3   # Average simply
  end
end

class String
  #----------------------------------------
  # Read PNG file
  #----------------------------------------
  # self: source path
  def read_png_to_img_aa
    src_path = self
    cnvs = ChunkyPNG::Canvas.from_file(src_path).grayscale
    if $dmon
      puts "w x h = %d x %d = %d" % [cnvs.width, cnvs.height, (cnvs.width * cnvs.height)]
      # puts "%0Xh" % cnvs[ 0, 0]
      # puts "%0Xh" % cnvs[10, 2]
      # tmp_a = cnvs.pixels   # flattened 1D-array of width x height
      # pp tmp_a.size
      # pp tmp_a.class
    end
    #------------------------------------------------------------
    # Convert to a gray value 2D-array, array of array
    #------------------------------------------------------------
    img_aa = 0.upto(cnvs.height-1).map{|y|
      cnvs.row(y).map{|v_4byte|       # value: 32bit RGBA
        (v_4byte>>8).rgb24bit_to_gray8bit
      }
    }
    img_aa
  end
end
