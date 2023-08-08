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
      if col =~ %r[^\d\d\d\d\-\d\d\-\d\d$]
        d = Time.parse(col).strftime("%Y-%m-%dT%H:%M:%S%z")
        rec[:@timestamp] = d
      else
        rec[headers[j]] = d
      end
    end
    puts rec.to_json
  end
end
