$barcode_NW7_patcode_h = {
  # 9bit length
  "0" => [-1,  1, -1,  1, -1,  1,  1, -1, -1],
  "1" => [-1,  1, -1,  1, -1, -1,  1,  1, -1],
  "2" => [-1,  1, -1,  1,  1, -1,  1, -1, -1],
  "3" => [-1, -1,  1,  1, -1,  1, -1,  1, -1],
  "4" => [-1,  1, -1, -1,  1, -1,  1,  1, -1],
  "5" => [-1, -1,  1, -1,  1, -1,  1,  1, -1],
  "6" => [-1,  1,  1, -1,  1, -1,  1, -1, -1],
  "7" => [-1,  1,  1, -1,  1, -1, -1,  1, -1],
  "8" => [-1,  1,  1, -1, -1,  1, -1,  1, -1],
  "9" => [-1, -1,  1, -1,  1,  1, -1,  1, -1],
  "-" => [-1,  1, -1,  1,  1, -1, -1,  1, -1],
  "$" => [-1,  1, -1, -1,  1,  1, -1,  1, -1],
  # 10bit length
  ":" => [-1, -1,  1, -1,  1, -1, -1,  1, -1, -1],
  "/" => [-1, -1,  1, -1, -1,  1, -1,  1, -1, -1],
  "." => [-1, -1,  1, -1, -1,  1, -1, -1,  1, -1],
  "+" => [-1,  1, -1, -1,  1, -1, -1,  1, -1, -1],
  "a" => [-1,  1, -1, -1,  1,  1, -1,  1,  1, -1],
  "b" => [-1,  1,  1, -1,  1,  1, -1,  1, -1, -1],
  "c" => [-1,  1, -1,  1,  1, -1,  1,  1, -1, -1],
  "d" => [-1,  1, -1,  1,  1, -1, -1,  1,  1, -1]
}
ones_for_sync = Array.new(10, 1)
$CANDO_sync_char              = "a"
$barcode_NW7_CANDO_sync_left  = ones_for_sync + $barcode_NW7_patcode_h[$CANDO_sync_char]
$barcode_NW7_CANDO_sync_right = $barcode_NW7_patcode_h[$CANDO_sync_char] + ones_for_sync
