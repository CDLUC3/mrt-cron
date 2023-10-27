require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ERCTest < ObjHealthTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
    @mapping = {}
    @taskdef.fetch(:categorize, {}).each do |k,list|
      list.each do |v|
        @mapping[v] = k
      end
    end
  end

  def get_field_sym
    :erc_na
  end

  def run_test(ohobj)
    status = :PASS
    metadata = ohobj.build.get_object.fetch(:metadata, {})
    merc = metadata.fetch(get_field_sym, "").strip
    @mapping.each do |k,v|
      regx = Regexp.new(k)
      status = ObjectHealth.compare_state(status, v) if merc =~ regx
    end
    status
  end
end

class ErcWhatTest < ERCTest
  def get_field_sym
    :erc_what
  end
end

class ErcWhoTest < ERCTest
  def get_field_sym
    :erc_who
  end
end

class ErcWhenTest < ERCTest
  def get_field_sym
    :erc_when
  end
end