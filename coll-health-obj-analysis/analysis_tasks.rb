# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'
# All analysis task classes should reside in a file '*_task.rb'.
Dir["#{File.dirname(__FILE__)}/*_task.rb"].each { |file| require file }

# During the ANALYSIS phase, this class applies each of the analysis tasks
# configured in config/merritt_classifications.yml
class AnalysisTasks
  def initialize(objh, config)
    @oh = objh
    @config = config
    @tasks = []

    analysis = @config.fetch(:analysis_json, {})
    analysis.each do |k, v|
      task = ObjHealthTask.create(@oh, v, k)
      @tasks.append(task) unless task.nil?
    end
  end

  def run_tasks(ohobj)
    ohobj.analysis.init_object
    @tasks.each do |task|
      task.run_task(ohobj) if task.check_scope(ohobj)
    end
    ohobj
  end
end
