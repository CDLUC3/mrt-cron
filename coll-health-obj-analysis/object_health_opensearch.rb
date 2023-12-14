# frozen_string_literal: true

require 'json'
require 'opensearch'

# https://opensearch.org/docs/latest/clients/ruby/

class ObjectHealthOpenSearch
  def initialize(config)
    @INDEX = 'objhealth'
    @config = config
    osconfig = @config.fetch(:opensearch, {})
    osconfig[:transport_options] = osconfig.fetch(:transport_options, {})
    osconfig[:transport_options][:ssl] = osconfig[:transport_options].fetch(:ssl, {})
    osconfig[:transport_options][:ssl][:verify] = osconfig[:transport_options][:ssl].fetch(:verify, 'false') == 'true'
    @osclient = OpenSearch::Client.new(osconfig)
    begin
      @osclient.indices.create(index: @INDEX)
    rescue OpenSearch::Transport::Transport::Errors::BadRequest => e
      # index already exists
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
  def query(formatter, ifrom, limit, page_size)
    total = 0
    while (ifrom < total || total.zero?) && ifrom < limit
      res = @osclient.search(
        index: @INDEX,
        body: { query: formatter.query },
        size: page_size > limit ? limit : page_size,
        from: ifrom
      )
      total = res.fetch('hits', {}).fetch('total', {}).fetch('value', 0) if total.zero?
      res.fetch('hits', {}).fetch('hits', []).each do |doc|
        sdoc = doc.fetch('_source', {})
        formatter.make_result(sdoc)
      end
      ifrom += page_size
    end
  end
end
