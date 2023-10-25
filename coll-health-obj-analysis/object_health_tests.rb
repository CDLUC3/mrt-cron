require 'json'
require_relative 'oh_tasktest'
Dir[File.dirname(__FILE__) + '/*_test.rb'].each {|file| require file }

class ObjectHealthTests
  def initialize(oh, config)
    @oh = oh
    @config = config
    @tests = []

    @config.fetch('tests', {}).each do |k,v|
      test = ObjHealthTest.create(@oh, v, k)
      @tests.append(test) unless test.nil?
    end

  end

  def run_tests(ohobj)
    ohobj.tests.init_object
    ostate = :SKIP
    @tests.each do |test|
      next unless test.check_scope(ohobj)
      status = test.run_test(ohobj)
      ohobj.tests.record_test(test.name, status)
      ostate = ObjectHealth.compare_state(ostate, status)
      ohobj.tests.append_key(:summary, test.name) unless status == :PASS || status == :SKIP
    end
    ohobj.tests.set_key(:state, ostate)
    ohobj
  end
end
