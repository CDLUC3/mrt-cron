# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'
Dir["#{File.dirname(__FILE__)}/*_test.rb"].sort.each { |file| require file }

# During the TEST phase, this class applies each of the tests configured in config/merritt_classifications.yml
class ObjectHealthTests
  def initialize(objh, config)
    @oh = objh
    @config = config
    @tests = []

    tests = @config.fetch(:tests, {})
    tests.each do |k, v|
      test = ObjHealthTest.create(@oh, v, k)
      @tests.append(test) unless test.nil?
    end
  end

  def run_tests(ohobj)
    ohobj.tests.init_object
    ostate = :SKIP
    @tests.each do |test|
      status = test.check_scope(ohobj) ? test.run_test(ohobj) : :SKIP
      ohobj.tests.record_test(test.name, status)
      ostate = ObjectHealthUtil.compare_state(ostate, status)
      ohobj.tests.append_key(:summary, test.name) unless %i[PASS SKIP].include?(status)
    end
    ohobj.tests.set_key(:state, ostate)
    ohobj
  end
end
