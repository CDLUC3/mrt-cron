class UnsustainableMimeFormatter < OSFormatter
  def initialize(options, osfdef)
    super(options, osfdef)
    @mimes_to_report = []
  end

  def init_test
    @mimes_to_report = []
    @doc.fetch("analysis", {}).fetch("mimes_by_status", {}).each do |k, v|
      next if k == "PASS"
      v.each do |m|
        @mimes_to_report.append(m)
      end
    end
  end

  def has_file_test
    true
  end

  def file_test(f)
    return false if f.fetch("ignore_file", false)
    m = f.fetch("mime_type", "")
    b = @mimes_to_report.include?(m)
    if b == false && m =~ %r[;]
      m = m.split(";")[0]
      b = @mimes_to_report.include?(m)
    end
    b
  end
end