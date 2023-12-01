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

  # https://opensearch.org/docs/latest/query-dsl/match-all/
  # q = {match: {"tests.summary": "unsustainable-mime-type"}}
  def query(q)
    size = 10
    ifrom = 0
    total = 0
                        
    while ifrom < total || ifrom == 0 do 
      res = @osclient.search(
        index: @INDEX,
        body: {query: q},
        size: size,
        from: ifrom
      ) 
      if total == 0
        total = res.fetch("hits", {}).fetch("total", {}).fetch("value", 0)
        puts total
      end
      res.fetch("hits", {}).fetch("hits", []).each do |doc|
        sdoc = doc.fetch("_source", {})
        puts sdoc.fetch("id", "")
                        
        #puts sdoc.fetch("tests", {}).fetch("results", {}).fetch("unsustainable-mime-type", "")
      end
      ifrom += size
    end
                        
  end

end
