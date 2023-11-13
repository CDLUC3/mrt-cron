require 'json'
require 'mustache'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class CollectionTagTask < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def run_task(ohobj)
    m = ohobj.mnemonic
    ark = ohobj.ark
    unless m.empty?
      tags = @oh.collection_taxonomy(m.to_sym)
      ohobj.analysis.set_subkey(:containers, :collection_set, tags)
      ohobj.analysis.set_subkey(:containers, :url, "https://merritt.cdlib.org/m/#{ark}")
    end
    ohobj
  end

end