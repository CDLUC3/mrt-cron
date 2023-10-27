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

  def get_status
    :PASS
  end

  def run_test(ohobj)
    status = :PASS
    ohobj.build.get_object.fetch(:producer, {}).each do |v|
      status = get_status if v.fetch(:pathtype, '').to_sym == get_filetype
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

  def get_status
    :WARN
  end
end

class ExtNotPresentTest < ExtTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def get_filetype
    :url
  end

  def get_status
    :FAIL
  end
end