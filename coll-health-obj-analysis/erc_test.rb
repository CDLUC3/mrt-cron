# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# Evaluate the contents of a Merritt ERC field.
# Derived versions of this class will test specific fields.
# See config/merritt_classifications.yml for the pattern matches that the class will apply
class ERCTest < ObjHealthTest
  def status_matcher(status)
    @taskdef.fetch(:status_matcher, {}).fetch(status, {})
  end

  def field_sym
    :erc_na
  end

  def run_test(ohobj)
    status = :PASS
    metadata = ohobj.build.hash_object.fetch(:metadata, {})
    merc = metadata.fetch(field_sym, '').strip
    ObjectHealthUtil.status_values.each do |stat|
      next unless ObjectHealthMatch.match_criteria(criteria: status_matcher(stat), key: merc, ohobj: ohobj,
        criteria_list: :values, criteria_patterns: :patterns)

      status = stat
      break
    end
    status
  end
end

# Evaluate Merritt erc_what field against patterns defined in a yaml file
class ErcWhatTest < ERCTest
  def field_sym
    :erc_what
  end
end

# Evaluate Merritt erc_who field against patterns defined in a yaml file
class ErcWhoTest < ERCTest
  def field_sym
    :erc_who
  end
end

# Evaluate Merritt erc_when field against patterns defined in a yaml file
class ErcWhenTest < ERCTest
  def field_sym
    :erc_when
  end
end
