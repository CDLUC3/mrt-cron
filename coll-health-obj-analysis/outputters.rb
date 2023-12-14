# frozen_string_literal: true

class OutputConfig
  def initialize(merritt_config)
    @merritt_config = merritt_config
  end
end

class ConsoleOutput < OutputConfig
  def output(rec, index)
    puts "#{index}. #{rec[:ark]} (#{rec[:producer_count]} files)"
    rec.fetch(:files, []).each do |f|
      puts "\t#{f.fetch(:path, '')} (#{f.fetch(:mime_type, '')})"
    end
  end
end

class ArksOutput < OutputConfig
  def output(rec, _index)
    puts rec[:ark]
  end
end

class FilesOutput < OutputConfig
  def output(rec, _index)
    rec.fetch(:files, []).each do |f|
      puts f.fetch(:url, '') unless f.fetch(:url, '').empty?
    end
  end
end
