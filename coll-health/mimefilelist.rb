require "json"

@collcount = {}
@colls = {}

def get_rec(columns)
  rec = {
    id: columns[0],
    mnemonic: columns[1],
    mime: columns[2],
    ark: columns[3],
    path: columns[4].gsub(%r[^producer\/],""),
    created: columns[5],
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

File.open("#{COLLHDATA}/files_details.ndjson", "w") do |f|
  ARGF.each_with_index do |line, i|
    next if line =~ %r[^id]
    rec = get_rec(line.strip!.split("\t"))
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
