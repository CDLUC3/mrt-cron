require 'json'
require 'opensearch'

# https://opensearch.org/docs/latest/clients/ruby/

class ObjectHealthOpenSearch
  def initialize(oh, config)
    @INDEX = 'objhealth'
    @oh = oh
    @config = config
    osconfig = @config.fetch(:opensearch, {})
    osconfig[:transport_options] = osconfig.fetch(:transport_options, {})
    osconfig[:transport_options][:ssl] = osconfig[:transport_options].fetch(:ssl, {})
    osconfig[:transport_options][:ssl][:verify] = osconfig[:transport_options][:ssl].fetch(:verify, "false") == "true"
    @osclient = OpenSearch::Client.new(osconfig)
    begin
      @osclient.indices.create(index: @INDEX)
    rescue OpenSearch::Transport::Transport::Errors::BadRequest => e 
      #index already exists
    end
  end

  def export(ohobj)
    resp = @osclient.index(
      index: @INDEX,
      body: ohobj.get_osobj,
      id: ohobj.id,
      refresh: true
    )
  end
end
