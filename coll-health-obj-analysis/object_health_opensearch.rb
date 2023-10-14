require 'json'
require 'opensearch'

# https://opensearch.org/docs/latest/clients/ruby/

class ObjectHealthOpenSearch
  def initialize(oh, config)
    @INDEX = 'objhealth'
    @oh = oh
    @config = config
    @osclient = OpenSearch::Client.new(@config.fetch("opensearch", {}))
    begin
      @osclient.indices.create(index: @INDEX)
    rescue OpenSearch::Transport::Transport::Errors::BadRequest => e 
      puts e.class
    end
  end

  def export(obj)
    resp = @osclient.index(
      index: @INDEX,
      body: obj.get_obj,
      id: obj.id,
      refresh: true
    )
    puts "RESP: #{resp['result']} #{resp['_version']}"
  end
end
