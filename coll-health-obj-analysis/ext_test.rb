require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ExtTest < ObjHealthTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def get_filetype
    :file
  end

  def run_test(ohobj)
    status = :PASS
    ohobj.build.get_object.fetch(:producer, {}).each do |v|
      status = report_status if v.fetch(:pathtype, '').to_sym == get_filetype
    end
    status
  end
end

class ExtUrlTest < ExtTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def get_filetype
    :url
  end
end

class ExtNotPresentTest < ExtTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def get_filetype
    :na
  end
end