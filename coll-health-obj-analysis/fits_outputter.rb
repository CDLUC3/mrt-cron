require 'nokogiri'

class FitsOutput < OutputConfig
  def initialize(merritt_config)
    super(merritt_config)
  end

  def merritt_cred
    @merritt_config.fetch(:credential, '')
  end

  def fileid_basename
    "/tmp/object_health_test."
  end

  def fits_output
    "/tmp/fits.xml"
  end

  def cleanup_last_fileid
    system("rm -f #{fileid_basename}* #{fits_output}")
  end 

  def download_file_to_identify(fname, furl)
    return if merritt_cred.empty?
    return if furl.empty?
    system("curl -s -L -o #{fname} -u '#{merritt_cred}' '#{furl}'")
  end

  def run_fits(fname)
    return unless File.exists?(fname)
    fitscmd = @merritt_config.fetch(:fits_command, "") 
    return if fitscmd.empty?
    fitscfg = @merritt_config.fetch(:fits_config, "")
    return if fitscfg.empty?
    system("#{fitscmd} -f #{fitscfg} -i '#{fname}' > #{fits_output}") 
  end

  def format_fits_output
    return unless File.exists?(fits_output)
    begin
      xml = Nokogiri::XML(File.read(fits_output)).remove_namespaces!
      puts xml.xpath("/fits/identification")
      puts xml.xpath("/fits/fileinfo")
      puts xml.xpath("/fits/filestatus")
    rescue => exception
      puts exception
    end
  end

  def output(rec, index)
    puts "#{index}. #{rec[:ark]} (#{rec[:producer_count]} files)"
    rec.fetch(:files, []).each do |f|
      puts "\t#{f.fetch(:path, '')} (#{f.fetch(:mime_type, '')})"
      puts 
      fname = "#{fileid_basename}#{f[:ext]}"
      cleanup_last_fileid
      download_file_to_identify(fname, f[:url])
      run_fits(fname)
      format_fits_output
      puts
    end
  end
end