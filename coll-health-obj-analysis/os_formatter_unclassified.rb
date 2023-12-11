class UnclassifiedMimeFormatter < OSFormatter
  def initialize(options, osfdef)
    super(options, osfdef)
    @files_to_report = []
  end

  def init_test
    @files_to_report = []
    @doc.fetch("analysis", {}).fetch("unclassified_mime_files", {}).each do |v|
      @files_to_report.append(v.fetch("path", []))
    end
  end

  def has_file_test
    true
  end

  def file_test(f)
    return false unless file_filters(f)
    @files_to_report.include?(f.fetch('pathname', ''))
  end
end