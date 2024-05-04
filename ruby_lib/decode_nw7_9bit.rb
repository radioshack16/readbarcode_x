require 'pp'
require 'fileutils'

require './global_defs.rb'
require './ruby_lib/nsa_extend.rb'

class Array
  #--------------------------------------------------
  # Decode NW-7 9bit code, selecting the nearest one
  #--------------------------------------------------
  # input: 9-element analog level array
  #   e.g. [-64.3, +63.9, ..., +62.3, -61.4]    // consisits of 9 element
  #           sign:   negative/positive: black/white
  # return: character: e.g.: "0", "1", ...
  def nw7_9bit_code_to_char
    in_a  = self
    c = ""
    char_a = ["0", "1", "2", "3", "4",
              "5", "6", "7", "8", "9",
              "-", "$"]
    corr_a = char_a.map{|x|
      [(in_a.inner_product $barcode_NW7_patcode_h[x]), x]
    }
    pair = corr_a.max_by{|v, c| v}
    c = pair[1]
    if $dmon
      #---
      # Monitor
      puts "---"
      pp char_a
      puts "---"
      pp corr_a
      puts "---"
      pp pair
      puts c
      #---
    end
    c
  end
end
