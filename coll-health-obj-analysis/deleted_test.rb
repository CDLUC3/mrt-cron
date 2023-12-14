# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class DeletedTest < ObjHealthTest
  def run_test(ohobj)
    ohobj.build.hash_object.fetch(:file_counts, {}).fetch(:deleted, 0).positive? ? report_status : :PASS
  end
end
