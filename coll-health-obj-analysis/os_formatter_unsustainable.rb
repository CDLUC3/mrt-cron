# frozen_string_literal: true

class UnsustainableMimeFormatter < OSFormatter
  def initialize(options, osfdef)
    super(options, osfdef)
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
