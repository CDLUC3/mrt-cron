class OutputConfig
  def initialize(merritt_config)
    @merritt_config = merritt_config
  end
end

class ConsoleOutput < OutputConfig
  def initialize(merritt_config)
    super(merritt_config)
  end

  def output(rec, index)
    puts "#{index}. #{rec[:ark]} (#{rec[:producer_count]} files)"
    rec.fetch(:files, []).each do |f|
      puts "\t#{f.fetch(:path, '')} (#{f.fetch(:mime_type, '')})"
    end
  end
end

class ArksOutput < OutputConfig
  def initialize(merritt_config)
    super(merritt_config)
  end

  def output(rec, index)
    puts rec[:ark]
  end
end

class FilesOutput < OutputConfig
  def initialize(merritt_config)
    super(merritt_config)
  end

  def output(rec, index)
    rec.fetch(:files, []).each do |f|
      puts f.fetch(:url, '') unless f.fetch(:url, '').empty?
    end
  end
end