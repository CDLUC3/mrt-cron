# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ExtTest < ObjHealthTest
  def filetype
    :file
  end

  def run_test(ohobj)
    status = :PASS
    ohobj.build.hash_object.fetch(:producer, {}).each do |v|
      status = report_status if v.fetch(:pathtype, '').to_sym == filetype
    end
    status
  end
end

class ExtUrlTest < ExtTest
  def filetype
    :url
  end
end

class ExtNotPresentTest < ExtTest
  def filetype
    :na
  end
end
