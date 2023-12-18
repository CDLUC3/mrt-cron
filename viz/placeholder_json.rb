# frozen_string_literal: true

require 'json'
require 'time'

keyset = {}

headers = []
ARGF.each_with_index do |line, i|
  if i.zero?
    headers = line.strip!.split("\t")
  else
    la = line.strip!.split("\t")
    la[10] = 0
    la[11] = 0
    la[12] = 0
    la[4] = Time.now.strftime('%Y-%m-%d')
    keyset[la.join("\t")] = 0
  end
end
keyset.each_key do |line|
  rec = {}
  line.split("\t").each_with_index do |col, j|
    d = col
    d = Integer(col) if col =~ /^\d+$/
    if col =~ /^\d\d\d\d-\d\d-\d\d$/
      d = Time.parse(col).strftime('%Y-%m-%dT%H:%M:%S%z')
      rec[:@timestamp] = d
    else
      rec[headers[j]] = d
    end
  end
  puts rec.to_json
end
