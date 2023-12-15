# frozen_string_literal: true

require 'json'
require 'time'

@start_date = ARGV.shift
# append to prior output file unless re-creating the entire dataset
@start_date = '2013-05-22 00:00:00' if @start_date.empty? || @start_date == 'all'

headers = []
ARGF.each_with_index do |line, i|
  if i.zero?
    headers = line.strip!.split("\t")
  else
    rec = {}
    line.strip!.split("\t").each_with_index do |col, j|
      d = col
      d = Integer(col) if col =~ /^\d+$/
      if col =~ /^\d\d\d\d-\d\d-\d\d$/
        d = Time.parse(col).strftime('%Y-%m-%dT%H:%M:%S%z')
        rec[:@timestamp] = d
      else
        rec[headers[j]] = d
      end
    end
    puts rec.to_json if rec.fetch(:@timestamp, '')[0, 10] > @start_date
  end
end
