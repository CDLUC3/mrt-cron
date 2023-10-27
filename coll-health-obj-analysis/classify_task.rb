require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ClassifyTask < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
    @categories = @taskdef.fetch(:categorize, [])
  end

  def run_task(ohobj)
    ohobj.analysis.zero_subkey(:classification, :na)
    ohobj.analysis.set_subkey(:mime_classification, :na, [])
    @categories.each do |cat|
      name = cat.fetch(:name, 'na').to_sym
      ohobj.analysis.zero_subkey(:classification, name)
      ohobj.analysis.set_subkey(:mime_classification, name, [])
    end

    ohobj.build.get_object.fetch(:producer, []).each do |f|
      mime = f[:mime_type].to_sym
      path = f[:pathname]
      categorization = :na
      @categories.each do |cat|
        name = cat.fetch(:name, 'na').to_sym
        cat.fetch(:mimes, {}).keys.each do |m|
          if m == mime
            categorization = name
            break
          end
        end
        break if categorization != :na
      end
      ohobj.analysis.increment_subkey(:classification, categorization)
      ohobj.analysis.append_subkey(:mime_classification, categorization, mime) unless ohobj.analysis.get_object.fetch(:mime_classification, {}).fetch(categorization, []).include?(mime)
    end

    fclass = ohobj.analysis.get_object.fetch(:classification, {})
    omimes = ohobj.analysis.get_object.fetch(:mime_classification, {})

    ohobj.analysis.set_key(:object_classification, :unknown)
    if fclass.fetch(:complex, 0) > 0 || omimes.fetch(:content, []).length > 1
      ohobj.analysis.set_key(:object_classification, :complex_object)
    elsif fclass.fetch(:content, 0) > 1 
      ohobj.analysis.set_key(:object_classification, :multi_digital_files)
    elsif fclass.fetch(:content, 0) == 1 && fclass.fetch(:derivatives, 0) > 0
      ohobj.analysis.set_key(:object_classification, :digital_file_with_derivatives)
    elsif fclass.fetch(:content, 0) == 0 && fclass.fetch(:derivatives, 0) > 0
      ohobj.analysis.set_key(:object_classification, :derivatives_only)
    elsif fclass.fetch(:content, 0) == 1 
      ohobj.analysis.set_key(:object_classification, :single_digital_file)
    elsif fclass.fetch(:content, 0) == 0 
      ohobj.analysis.set_key(:object_classification, :no_content)
    end

    ohobj.analysis.set_key(:metadata_classification, :unknown)
    if fclass.fetch(:metadata, 0) > 1 
      ohobj.analysis.set_key(:metadata_classification, :multi_metadata)
    elsif fclass.fetch(:metadata, 0) == 1 && fclass.fetch(:secondary, 0) > 0
      ohobj.analysis.set_key(:metadata_classification, :metadata_with_secondary)
    elsif fclass.fetch(:metadata, 0) == 1 && fclass.fetch(:secondary, 0) == 0
      ohobj.analysis.set_key(:metadata_classification, :single_metadata_file)
    elsif fclass.fetch(:metadata, 0) == 0 && fclass.fetch(:secondary, 0) > 0
      ohobj.analysis.set_key(:metadata_classification, :secondary_only)
    elsif fclass.fetch(:metadata, 0) == 0 && fclass.fetch(:secondary, 0) == 0
      ohobj.analysis.set_key(:metadata_classification, :no_metadata)
    end
    ohobj
  end
end