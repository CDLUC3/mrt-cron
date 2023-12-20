# frozen_string_literal: true

# base outputter for an Object Health query result
class OutputConfig
  def initialize(merritt_config)
    @merritt_config = merritt_config
  end
end

# default consonle outputter for an Object Health query result
class ConsoleOutput < OutputConfig
  def output(rec, index)
    puts "#{index}. #{rec[:ark]} (#{rec[:producer_count]} files)"
    rec.fetch(:files, []).each do |f|
      sz = f.fetch(:billable_size, 0)
      puts "\t#{f.fetch(:path, '')} (#{f.fetch(:mime_type, '')}) #{ObjectHealthUtil.num_format(sz)}"
    end
  end
end

# ark outputter for an Object Health query result
class ArksOutput < OutputConfig
  def output(rec, _index)
    puts rec[:ark]
  end
end

# merritt file url outputter for an Object Health query result
class FilesOutput < OutputConfig
  def output(rec, _index)
    rec.fetch(:files, []).each do |f|
      puts f.fetch(:url, '') unless f.fetch(:url, '').empty?
    end
  end
end
