require 'json'
require 'time'

headers = []
ARGF.each_with_index do |line, i|
  if i == 0
    headers = line.strip!.split("\t") 
 else
    rec = {}
    line.strip!.split("\t").each_with_index do |col, j|
      d = col
      d = Integer(col) if col =~ %r[^\d+$]
      d = Time.parse(col).strftime("%Y-%m-%d %H:%M:%S %z") if col =~ %r[^\d\d\d\d\-\d\d\-\d\d$]
      rec[headers[j]] = d
    end
    puts rec.to_json
  end
end
