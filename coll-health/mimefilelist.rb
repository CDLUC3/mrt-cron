require "json"

@collcount = {}
@colls = {}
@currec = []

@lastmnemonic = ""

def write_file
  puts @lastmnemonic
  if @currec.length > 0 && @lastmnemonic !~ %r[_sla$]
    File.open("#{@lastmnemonic}.out.json", "w") do |f|
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
  end
  @currec = []
end

ARGF.each_with_index do |line, i|
  next if i == 0
  columns = line.strip!.split("\t")
  mnemonic = columns[0]
  next if mnemonic.empty?
  mime = columns[1]
  ark = columns[2]
  path = columns[3].gsub(%r[^producer\/],"")
  rec = {mnemonic: mnemonic, mime: mime, ark: ark, path: path}
  @currec.push(rec)
  coll = @colls.fetch(mnemonic,{})
  coll[mime] = coll.fetch(mime, 0) + 1
  @colls[mnemonic] = coll
  @collcount[mnemonic] = @collcount.fetch(mnemonic, 0) + 1
  next if @lastmnemonic == mnemonic
  write_file unless @lastmnemonic.empty?
  @lastmnemonic = mnemonic
end
write_file unless @lastmnemonic.empty?

@colls.sort_by {|k,v| k}.each do |c, coll|
  coll.sort_by{|k,v| -v}.each do |m,v|
    puts sprintf("%-20s %-10d %s", c, v, m)
  end
end
