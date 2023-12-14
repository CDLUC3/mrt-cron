# frozen_string_literal: true

class ExtensionMismatchFormatter < OSFormatter
  def initialize(options, osfdef)
    super(options, osfdef)
    @files_to_report = []
  end

  def init_test
    @files_to_report = []
    @doc.fetch('analysis', {}).fetch('mime_ext_mismatch', {}).each do |v|
      v.fetch('files', []).each do |f|
        @files_to_report.append(f)
      end
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
