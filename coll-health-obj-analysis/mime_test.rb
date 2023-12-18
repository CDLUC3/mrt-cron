# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# Merritt Object Health Test returning the sustainability status of the least sustainable
# file mime type within the object.  Sustainability status is defined in config/merritt_classifications.yml
class MimeTest < ObjHealthTest
  def run_test(ohobj)
    status = :SKIP
    m = ohobj.analysis.hash_object.fetch(:mimes_by_status, {})
    ObjectHealthUtil.status_values.each do |stat|
      status = stat if m.fetch(stat, []).length.positive?
    end
    status
  end
end

# Merritt Object Health Test which evaluates if any file within the object has a
# mime type that is not associated with a specific file extension
class MimeExtTest < ObjHealthTest
  def run_test(ohobj)
    ohobj.analysis.hash_object.fetch(:mime_ext_mismatch, []).empty? ? :PASS : :FAIL
  end
end

# Merritt Object Health Test which evaluates if any file within the object has a
# mime type which has a qualified association (status) with a file extension
class UnexpectedMimeExtTest < ObjHealthTest
  def run_test(ohobj)
    status = :PASS
    ohobj.analysis.hash_object.fetch(:mime_ext_status, []).each do |v|
      stat = v.fetch(:status, :PASS)
      status = ObjectHealthUtil.compare_state(status, stat)
    end
    status
  end
end

# Merritt Object Health Test which evaluates if any file within the object has a mime type
# that has not been categorized with a sustainability status in config/merritt_classifications.yml
class MimeNotFoundTest < ObjHealthTest
  def run_test(ohobj)
    ohobj.analysis.hash_object.fetch(:mimes_by_status, {}).fetch(:SKIP, []).empty? ? :PASS : :FAIL
  end
end

# Merritt Object Health Test which evaluates if any file within the object has a path name or mimetype
# that is to be ignored by classification tasks (example: git files)
class IgnoreFileTest < ObjHealthTest
  def run_test(ohobj)
    ohobj.build.hash_object.fetch(:ignore_files, []).empty? ? :PASS : :INFO
  end
end
