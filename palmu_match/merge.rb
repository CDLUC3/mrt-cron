require 'json' 

# assume inventory.txt is local - it should not change
# run sql > pm.loaded.txt
# ruby merge.rb
# aws s3 cp match.json s3://uc3-s3-prd/merritt-reports/palmu/match.json

@files = {}
@matched = 0
@not_loaded = 0
@not_in_inventory = 0
@ignored = 0

File.open("pm.loaded.txt", "r").each_line do |line|
    tt = line.strip
    tt = line.strip.split(%r[\/])[-1] unless line =~ %r[conservation]
    tt.gsub!("'", '')
    @files[tt] = @files.fetch(tt, {key: tt})
    @files[tt][:loaded] = true
end

File.open("inventory.txt", "r").each_line do |line|
    next if line =~ %r[mods\/]
    next unless line =~ %r[\/]
    next if line =~ %r[\/$]
    t = line.strip.split(%r[\/])
    next if t[-1] =~ %r[^\._]
    tt = t.length > 3 ? t[2,t.length].join('/') : t[-1]
    tt = t[-1] unless tt =~ %r[conservation]
    tt.gsub!("'", "")
    @files[tt] = @files.fetch(tt, {key: tt})
    @files[tt][:inventory] = true
end

@data = []
@files.keys.sort.each do |k|
    v = @files[k]
    if v[:inventory] && v[:loaded]
        v[:status] = "Matched"
        @matched += 1
    elsif k !~ %r[(^|\/)\d\d\d\d\.\d\d\.]
        v[:status] = "Ignored"
        @ignored += 1
    elsif v[:inventory]
        v[:status] = "Not Loaded"
        @not_loaded += 1
    elsif v[:loaded]
        v[:status] = "Not in inventory"
        @not_in_inventory += 1
        puts k
    end
    @files[k] = v
    @data.push(v)
end

File.open("match.json", "w") do |f|
  f.write("const DATA = ")
  f.write(@data.to_json)
  f.write(";")
end

puts "Matched:         \t#{@matched}\t#{100*@matched/@files.length}%"
puts "Not Loaded:      \t#{@not_loaded}\t#{100*@not_loaded/@files.length}%"
puts "Not in inventory:\t#{@not_in_inventory}\t#{100*@not_in_inventory/@files.length}%"
puts "Ignored:         \t#{@ignored}\t#{100*@ignored/@files.length}%"