# frozen_string_literal: true

require 'nokogiri'

# Format and object health file path into an invocation of FITS (File Information Tool Set)
# for file identification.
# Parse the resulting XML into a readable format.
# https://projects.iq.harvard.edu/fits/home
class FitsOutput < OutputConfig
  def merritt_cred
    @merritt_config.fetch(:credential, '')
  end

  def fileid_basename
    '/tmp/object_health_test.'
  end

  def fits_output
    '/tmp/fits.xml'
  end

  def fits_err
    '/tmp/fits.err'
  end

  def cleanup_last_fileid
    system("rm -f #{fileid_basename}* #{fits_output} #{fits_err}")
  end

  def download_file_to_identify(fname, furl)
    return if merritt_cred.empty?
    return if furl.empty?

    system("curl -s -L -o #{fname} -u '#{merritt_cred}' '#{furl}'")
  end

  def run_fits(fname)
    return unless File.exist?(fname)

    fitscmd = @merritt_config.fetch(:fits_command, '')
    return if fitscmd.empty?

    fitscfg = @merritt_config.fetch(:fits_config, '')
    return if fitscfg.empty?

    system("#{fitscmd} -f #{fitscfg} -i '#{fname}' > #{fits_output} 2> #{fits_err}")
  end

  def record_stat(stat)
    # override in derived class
  end

  def format_fits_output
    return unless File.exist?(fits_output)

    begin
      xml = Nokogiri::XML(File.read(fits_output)).remove_namespaces!
      xml.xpath('/fits/identification').each do |doc|
        stat = doc.xpath('@status').text
        stat = 'NA' if stat.empty?
        c = doc.xpath('count(identity)')
        count = c > 1 ? "(#{c.to_i} identities)" : ''
        write "\t\tStatus: #{stat} #{count}"
        record_stat(stat)
        doc.xpath('identity').each do |id|
          tools = []
          id.xpath('tool').each do |t|
            tools.append(t.xpath('@toolname').text)
          end
          write "\t\t  #{id.xpath('@format')} (#{id.xpath('@mimetype')}): #{tools}"
          id.xpath('externalIdentifier').each do |ei|
            write "\t\t    #{ei.xpath('@type')}: #{ei.text}"
          end
        end
      end
      xml.xpath('/fits/filestatus').each do |doc|
        fswf = doc.xpath('well-formed').text
        unless fswf.empty?
          fswf = fswf == 'true' ? 'Well-formed' : 'NOT Well-formed'
        end
        fsv = doc.xpath('valid').text
        unless fsv.empty?
          fsv = fsv == 'true' ? 'Valid' : 'NOT Valid'
        end
        msg = doc.xpath('message[1]').text
        msg = "Msg: #{msg}" unless msg.empty?
        write "\t\t#{fswf}. #{fsv}. #{msg}" unless fswf.empty? && fsv.empty? && msg.empty?
      end
      # xml.xpath('/fits/fileinfo').each do |doc|
      #  doc.xpath('creatingApplicationName').each do |app|
      #    puts "\t\t- #{app.xpath('@status').text}: #{app.text}"
      #  end
      # end
      err = File.read(fits_err)
      unless err.empty?
        puts
        puts err
      end
    rescue StandardError => e
      puts e
    end
  end

  def output(rec, index)
    write "#{index}. #{rec[:ark]} (#{rec[:producer_count]} files)"
    rec.fetch(:files, []).each do |f|
      sz = f.fetch(:billable_size, 0)
      write "\t#{f.fetch(:path, '')} (#{f.fetch(:mime_type, '')}) #{ObjectHealthUtil.num_format(sz)}"
      write
      fname = "#{fileid_basename}#{f[:ext]}"
      cleanup_last_fileid
      download_file_to_identify(fname, f[:url])
      run_fits(fname)
      format_fits_output
      write
    end
    flush
  end

  def write(str = '')
    puts str
  end

  def flush; end
end

# Invoke FITS, only generate output if at least one file returns a status other than UNKNOWN
class FitsFilteredOutput < FitsOutput
  def initialize(merritt_config)
    @msg = []
    @interesting = false
    super(merritt_config)
  end

  def write(str = '')
    @msg.append(str)
  end

  def flush
    puts @msg if @interesting
    @msg = []
    @interesting = false
  end

  def record_stat(stat)
    @interesting = true unless stat == 'UNKNOWN'
  end
end
