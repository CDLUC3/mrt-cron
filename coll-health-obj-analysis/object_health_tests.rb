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
    @tests.each do |test|
      status = test.run_test(ohobj)
      ohobj.tests.record_test(test.name, status)
    end
    ohobj
  end
end
