require_relative 'object_health'

oh = ObjectHealth.new(ARGV)
oh.preliminary_tasks
oh.process_objects