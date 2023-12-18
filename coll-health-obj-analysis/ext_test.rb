# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# Merritt object test to determine if all file pathnames looks like filenames with file extensions
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

# Merritt object test to determine if any file pathname looks like a url fragment rather than a filename with a
# file extension
class ExtUrlTest < ExtTest
  def filetype
    :url
  end
end

# Merritt object test to determine if any file pathname has no discernable file extension
class ExtNotPresentTest < ExtTest
  def filetype
    :na
  end
end
