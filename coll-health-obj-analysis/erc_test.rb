# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ERCTest < ObjHealthTest
  def status_matcher(status)
    @taskdef.fetch(:status_matcher, {}).fetch(status, {})
  end

  def get_field_sym
    :erc_na
  end

  def run_test(ohobj)
    status = :PASS
    metadata = ohobj.build.get_object.fetch(:metadata, {})
    merc = metadata.fetch(get_field_sym, '').strip
    ObjectHealthUtil.status_values.each do |stat|
      next unless ObjectHealthMatch.match_criteria(criteria: status_matcher(stat), key: merc, ohobj: ohobj,
                                                   criteria_list: :values, criteria_patterns: :patterns)

      status = stat
      break
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
