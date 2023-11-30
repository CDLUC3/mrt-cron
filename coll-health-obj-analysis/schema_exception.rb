class MySchemaException < StandardError
  def initialize(errors)
    @errors = errors
  end

  def errors
    @errors
  end

  def print (label)
    puts "\n** Schema Validation Failure for #{label}" 
    @errors.each do |s|
      puts " - #{s}" 
    end
  end
end