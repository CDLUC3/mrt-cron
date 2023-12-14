# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'
# All analysis task classes should reside in a file '*_task.rb'.
Dir["#{File.dirname(__FILE__)}/*_task.rb"].sort.each { |file| require file }

# Load all analysis tasks defined in the merritt_classifications.yml file
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
