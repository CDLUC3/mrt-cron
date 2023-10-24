require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ERCTest < ObjHealthTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
    @mapping = {}
    @taskdef_with_sym.fetch(:categorize, {}).each do |k,list|
      list.each do |v|
        @mapping[v] = k.to_sym
      end
    end
  end

  def run_test(ohobj)
    status = :PASS
    metadata = ohobj.build.get_object.fetch(:metadata, {})
    mwho = metadata.fetch(:erc_who, "").strip
    mwhat = metadata.fetch(:erc_what, "").strip
    mwhen = metadata.fetch(:erc_when, "").strip
    @mapping.each do |k,v|
      regx = Regexp.new(k)
      status = ObjectHealth.compare_state(status, v) if mwho =~ regx
      status = ObjectHealth.compare_state(status, v) if mwhat =~ regx
      status = ObjectHealth.compare_state(status, v) if mwhen =~ regx
    end
    status
  end
end