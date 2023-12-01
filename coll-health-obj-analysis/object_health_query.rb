require_relative 'object_health'

class ObjectHealthQuery
  def initialize
    @oh = ObjectHealth.new([])
    @opensearch = @oh.opensearch
  end              

  def run_query
    @opensearch.query({match: {"tests.summary": "unsustainable-mime-type"}})
  end
end

ohq = ObjectHealthQuery.new
ohq.run_query
