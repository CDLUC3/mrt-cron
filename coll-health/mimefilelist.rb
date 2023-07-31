require "json"

@collcount = {}
@colls = {}
@currec = []
@notes = {content: "content", std_metadata: "std_metadata"}

@lastmnemonic = ""

def write_file
  return if @lastmnemonic.empty? || @lastmnemonic.nil?
  puts @lastmnemonic
  if @currec.length > 0 && @lastmnemonic !~ %r[_sla$]
    File.open("out/#{@lastmnemonic}.out.json", "w") do |f|
      curmimes = {}
      @colls[@lastmnemonic].sort_by {|k,v| -v}.each do|m,v|
        curmimes[m] = "#{sprintf('%05.1f', (v * 100.0) / @collcount[@lastmnemonic])}: #{m}: #{v}"
        puts "\t#{m}\t#{curmimes[m]}"
      end
      f.write("var filterMimes = #{curmimes.to_json};")
      f.write("const DATA = ")
      f.write(@currec.to_json)
      f.write(";")
    end
    File.open("out/#{@lastmnemonic}.out.ndjson", "w") do |f|
      @currec.each do |r|
        f.write(r.to_json)
        f.write("\n")
      end
    end  
  end
  @currec = []
end

def get_rec(mnemonic, mime, ark, path)
  path.gsub!(%r[^producer\/],"")
  note = "content"
  note = "std_metadata" if path =~ %r[^(mrt-datacite\.xml|mrt-oaidc\.xml|stash-wrapper\.xml)$]
  note = "std_metadata" if path =~ %r[^(nuxeo\.cdlib\.org/Merritt/.*\.xml)$]
  {mnemonic: mnemonic, mime: mime, ark: ark, path: path, note: note}
end

ARGF.each_with_index do |line, i|
  next if i == 0
  columns = line.strip!.split("\t")
  mnemonic = columns[0]
  next if mnemonic.empty? || mnemonic.nil?
  mime = columns[1]
  write_file unless @lastmnemonic == mnemonic 
  @lastmnemonic = mnemonic
  @currec.push(get_rec(mnemonic, mime, columns[2], columns[3]))
  coll = @colls.fetch(mnemonic,{})
  coll[mime] = coll.fetch(mime, 0) + 1
  @colls[mnemonic] = coll
  @collcount[mnemonic] = @collcount.fetch(mnemonic, 0) + 1
end
write_file 

@colls.sort_by {|k,v| k}.each do |c, coll|
  coll.sort_by{|k,v| -v}.each do |m,v|
    puts sprintf("%-20s %-10d %s", c, v, m)
  end
end
