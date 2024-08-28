# frozen_string_literal: true

# When formatting the results of an Object Health Query, extract only files with a non-sustainable mime type
class UnsustainableMimeFormatter < OSFormatter
  def initialize(options, osfdef)
    super
    @mimes_to_report = []
  end

  def init_test
    @mimes_to_report = []
    @doc.fetch('analysis', {}).fetch('mimes_by_status', {}).each do |k, v|
      next if k == 'PASS'

      v.each do |m|
        @mimes_to_report.append(m)
      end
    end
  end

  def file_test?
    true
  end

  def file_test(file)
    return false unless file_filters(file)

    m = file.fetch('mime_type', '')
    b = @mimes_to_report.include?(m)
    if b == false && m =~ /;/
      m = m.split(';')[0]
      b = @mimes_to_report.include?(m)
    end
    b
  end
end
