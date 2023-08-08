require "json"
require "date"

# usage ruby mimefilelist.rb date_time file

@start_date=ARGV.shift
# append to prior output file unless re-creating the entire dataset
@mode="a"
if @start_date.empty? || @start_date == "all" || @start_date == '2013-05-22 00:00:00'
  @start_date="2013-05-22 00:00:00"
  @mode="w"
end
@collcount = {}
@colls = {}

def get_rec(columns)
  return if columns.length < 10
  rec = {
    id: columns[0],
    mnemonic: columns[1],
    mime: columns[2],
    ark: columns[3],
    path: columns[4].gsub(%r[^producer\/],""),
    '@timestamp': DateTime("#{columns[5]} -0700").to_s,
    billable_size: columns[6].to_i,
    campus: columns[7],
    owner: columns[8],
    mime_group: columns[9],
    note: "content"
  }
  rec[:note] = "std_metadata" if rec[:path] =~ %r[^(mrt-datacite\.xml|mrt-oaidc\.xml|stash-wrapper\.xml)$]
  rec[:note] = "std_metadata" if rec[:path] =~ %r[^(nuxeo\.cdlib\.org/Merritt/.*\.xml)$]
  rec
end

File.open("#{ENV['COLLHDATA']}/files_details.ndjson", @mode) do |f|
  ARGF.each_with_index do |line, i|
    next if line =~ %r[^id]
    rec = get_rec(line.strip!.split("\t"))
    next if rec.nil?
    next if rec['@timestamp'] <= @start_date
    next if rec[:mnemonic] =~ %r[(_sla|_service_level_agreement)$]
    coll = @colls.fetch(rec[:mnemonic], {})
    coll[rec[:mime]] = coll.fetch(rec[:mime], 0) + 1
    @colls[rec[:mnemonic]] = coll
    @collcount[rec[:mnemonic]] = @collcount.fetch(rec[:mnemonic], 0) + 1
    f.write(rec.to_json)
    f.write("\n")
  end
end

@colls.sort_by {|k,v| k}.each do |c, coll|
  coll.sort_by{|k,v| -v}.each do |m,v|
    puts sprintf("%-20s %-10d %s", c, v, m)
  end
end
