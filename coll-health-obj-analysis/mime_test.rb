# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class MimeTest < ObjHealthTest
  def run_test(ohobj)
    status = :SKIP
    m = ohobj.analysis.get_object.fetch(:mimes_by_status, {})
    ObjectHealthUtil.status_values.each do |stat|
      status = stat if m.fetch(stat, []).length.positive?
    end
    status
  end
end

class MimeExtTest < ObjHealthTest
  def run_test(ohobj)
    ohobj.analysis.get_object.fetch(:mime_ext_mismatch, []).empty? ? :PASS : :FAIL
  end
end

class UnexpectedMimeExtTest < ObjHealthTest
  def run_test(ohobj)
    status = :PASS
    ohobj.analysis.get_object.fetch(:mime_ext_status, []).each do |v|
      stat = v.fetch(:status, :PASS)
      status = ObjectHealthUtil.compare_state(status, stat)
    end
    status
  end
end

class MimeNotFoundTest < ObjHealthTest
  def run_test(ohobj)
    ohobj.analysis.get_object.fetch(:mimes_by_status, {}).fetch(:SKIP, []).empty? ? :PASS : :FAIL
  end
end

class IgnoreFileTest < ObjHealthTest
  def run_test(ohobj)
    ohobj.build.get_object.fetch(:ignore_files, []).empty? ? :PASS : :INFO
  end
end
