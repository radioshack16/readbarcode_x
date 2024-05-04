#! ruby -EUTF-8
# -*- mode:ruby; coding:utf-8 -*-

#----------------------------------------
# Numeric, String and Array extention
#----------------------------------------
# K.Hirooka
# 2011/04/29, Fri.      Ruby v1.8.7
# 2015/01/19, Mon.      Ruby v2.1
# 2015/01/28, Wed.
# 2024/05/04, Sat.      Ruby v3,2,3
#------
require 'fileutils'
require 'nkf'

class Numeric
    def to_spaces
        s=""
        self.times{|i|
            s<<" "
        }
        s
    end
end

#
# Quote path string if necessary
# for the path to be able to have white spaces.
#

class String
    # input: array of string
    def is_member? ary
        ary.include?(self)
    end

    # self: file name
    # output: read text in UTF-8,
    #         whether the file kanji-code is UTF-8 or Shift-JIS.
    def read_to_s
        s = File.read(self, encoding: 'UTF-8')
        # DEBUG: pp NKF.guess(s)
        if NKF.guess(s)==NKF::SJIS
          # Read again as Shift-JIS and convert to UTF-8.
          File.open(self, mode = "rt:SJIS:UTF-8"){|f| s = f.read}
          # DEBUG: pp NKF.guess(s)
        end
        s
    end

    def qt
        ret = ""
        if self=~/^".*"$/
            ret = self           # as is.
        else
            ret = "\"#{self}\""  # quote.
        end
        return ret
    end

    def unquote
      ret = ""
      if self=~/^"(.*)"$/
        ret = $1
      else
        ret = self
      end
    end

    def to_basename
        File.basename(self)
    end

    def to_extname
        File.extname(self)
    end

    # Remove extention
    # e.g: "hoge.bmp".remove_ext    # => "hoge"
    def remove_ext
        ext_s=self.to_extname
        File.basename(self, ext_s)  # Remove extention
    end

    # Add extention
    # e.g.: "hoge".add_ext(".mjpeg")
    def add_ext(ext_s)
        self+ext_s
    end

    #
    # Assumes: applied to a basename.
    #
    def change_ext(ext_s)
        self.remove_ext.add_ext(ext_s)
    end

    def to_dirname
        File.dirname(self)
    end

    # Change drive of the self path.
    def to_drive(drv_s)
        if self=~/^.:(.*)/
            # Replace drive letter.
            s=drv_s+":"+$1
        else
            # No drive letter in self.
            s=drv_s+":"+self
        end
        s
    end

    # list up folders in the folder named by the self.
    # e.g.: ["a43", "BScinema"]
    def to_folderlist
        a = []
        Dir.glob(File.join(self, "*")).each {|f|
            a << File.basename(f) if File.directory?(f)
        }
        a
    end

    def to_mpegfilelist
        Dir.glob(File.join(self, "*.mpg"))
    end

    def to_bmpfilelist
        tmplist = []
        if !(File.exist?(self) && File.directory?(self))
            puts "Warning: no bmps folder: %s, [] returned from String#to_bmpfilelist." % self
            return []
        end
        tmplist = Dir.entries(self)
        tmplist.delete_if {|f|
            File.extname(f)!='.bmp'     # Use only bmp files.
        }
        a = tmplist.map {|f|
            File.basename(f, '.bmp')    # Remove extention '.bmp'.
        }
        a
    end

    def mkdir
      self.mkdir_p
    end

    def mkdir_p
        if !(File.exist?(self) && File.directory?(self))
            FileUtils.mkdir_p(self) # Recursive mkdir.
                    # Dir.mkdir(self)   # Not recursive.
        end
    end

    def file_exist?
      File.exist?(self)
    end


    def rmdir
      if File.exist?(self) && File.directory?(self)
        FileUtils.rm_rf(self)   # rmdir force
        puts "rmdir: " + self
      end
    end

    def to_file(fname, kanji_code=:UTF8, new_line=:LF)
                              #  {:UTF8, :SJIS}
      if fname=="" || fname==nil
        puts "Error: String#to_file: fname illegal: #{fname}"
        return
      end
      case kanji_code
      when :UTF8
        opt_kanji_s = "UTF-8"
      when :SJIS
        opt_kanji_s = "SJIS"
      else
        puts "Error: %s: unknown kanji_code: %s" % [__method__, kanji_code]
        exit
      end
      if new_line==:CRLF
        File.open(fname, "w:%s" % opt_kanji_s) {|f|
          f.puts self
        }
      else
        File.open(fname, "wb:%s" % opt_kanji_s) {|f|
          f.puts self
        }
      end
    end

    # Return the folder where the bmps reside.
    # The bmps will be splitted from a src mpeg and stored there,
    # or read for deciding start frame.
    #
    # self: srcpath of a mpeg file
    def to_bmp_folder
        abspath     = File.expand_path(self)    # absolute path
        dirname     = File.dirname(abspath)     # the same as the source file.
        basename    = File.basename(abspath)
        ext         = File.extname(basename)
        #
        dstfolder   = File.join(dirname, basename.sub(/#{ext}$/, "")+"_lowresbmps")
        dstfolder
    end

    # Applicable to a path
    def path_openable_in_append?
        flg=false
        File.open(self, "r+b") {|f|
            pp f
        }
        return flg
    end

    def echo
        puts self
    end

    def run
        system(self)
    end

    def each_line_shift_r(n)
        s=""
        self.each_line{|x|
            s<<n.to_spaces+x
        }
        s
    end

end

class Array
  def avg
    a = self
    n = a.size
    if n==0
      puts "Error: size = %d, unexpected, at %s" % [n, __method__];exit
    end
    a.sum / n
  end

  #----------------------------------------
  # Sum-normalize
  #----------------------------------------
  def sum_normalize
    a = self
    k = 1/a.sum.to_f
    a.map{|x| x*k}
  end

  # Normalize values with tgt
  # only if maximum is positive.
  def normalize(tgt)
    max_v = self.max.to_f
    if max_v <= 0.0
      return self   # as is
    end
    coef = tgt/max_v
    self.map{|v|
      v * coef
    }
  end

  def to_abs_a
    self.map{|v|
      v.abs
    }
  end

  def to_abs2_a
    self.map{|v|
      v.abs2
    }
  end

  def sum_of_abs
    self.to_abs_a.sum
  end

  def inner_product v2_a
    v1_a = self
    v1_a.map.with_index{|v1, k|
      v1 * v2_a[k]
    }.sum
  end

    def car
        self[0]
    end

    def cdr
        self[1..(self.size-1)]
    end

    def cddr
        self.cdr.cdr
    end

    def caar
        self.car.car
    end

    def cdddr
        self.cddr.cdr
    end

    def cadr
        self.cdr.car
    end

    def caddr
        self.cddr.car
    end

    def cadddr
        self.cdddr.car
    end

    def caadr
        self.cdr.caar
    end

    def caaddr
        self.cddr.caadr
    end

    def to_file(fname, kanji_code=:UTF8, new_line=:LF)
                              #  {:UTF8, :SJIS}
      if fname=="" || fname==nil
        puts "Error: Array#to_file: fname illegal: #{fname}"
        return
      end
      case kanji_code
      when :UTF8
        opt_kanji_s = "UTF-8"
      when :SJIS
        opt_kanji_s = "SJIS"
      else
        puts "Error: %s: unknown kanji_code: %s" % [__method__, kanji_code]
        exit
      end
      if new_line==:CRLF
        File.open(fname, "w:%s" % opt_kanji_s) {|f|
          f.puts self
        }
      else
        File.open(fname, "wb:%s" % opt_kanji_s) {|f|
          f.puts self
        }
      end
    end
end
