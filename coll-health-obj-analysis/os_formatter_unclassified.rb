# frozen_string_literal: true

class UnclassifiedMimeFormatter < OSFormatter
  def initialize(options, osfdef)
    super(options, osfdef)
    @files_to_report = []
  end

  def init_test
    @files_to_report = []
    @doc.fetch('analysis', {}).fetch('unclassified_mime_files', {}).each do |v|
      @files_to_report.append(v.fetch('path', []))
    end
  end

  def file_test?
    true
  end

  def file_test(file)
    return false unless file_filters(file)

    @files_to_report.include?(file.fetch('pathname', ''))
  end
end
