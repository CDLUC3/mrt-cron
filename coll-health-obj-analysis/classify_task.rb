require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ClassifyTask < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
    @categories = @taskdef_with_sym.fetch(:categorize, [])
    puts @categories
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
      mime = f[:mime_type]
      path = f[:pathname]
      categorization = :na
      @categories.each do |cat|
        name = cat.fetch(:name, 'na').to_sym
        cat.fetch(:mimes).each do |m|
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
      ohobj.analysis.set_key(:object_classification, :complex)
    elsif fclass.fetch(:content, 0) > 1 && fclass.fetch(:metadata, 0) > 0
      ohobj.analysis.set_key(:object_classification, :multi_content_with_metadata)
    elsif fclass.fetch(:content, 0) > 1 && fclass.fetch(:secondary, 0) > 0
      ohobj.analysis.set_key(:object_classification, :multi_content_with_secondary)
    elsif fclass.fetch(:content, 0) == 1 && fclass.fetch(:metadata, 0) > 0
      ohobj.analysis.set_key(:object_classification, :content_with_metadata)
    elsif fclass.fetch(:content, 0) == 1 && fclass.fetch(:secondary, 0) > 0
      ohobj.analysis.set_key(:object_classification, :content_with_secondary)
    elsif fclass.fetch(:content, 0) == 0 && fclass.fetch(:metadata, 0) > 0
      ohobj.analysis.set_key(:object_classification, :metadata_only)
    elsif fclass.fetch(:content, 0) == 0 && fclass.fetch(:secondary, 0) > 0
      ohobj.analysis.set_key(:object_classification, :secondary_only)
    elsif fclass.fetch(:content, 0) > 1 
      ohobj.analysis.set_key(:object_classification, :multi_content_no_metadata)
    elsif fclass.fetch(:content, 0) == 1 
      ohobj.analysis.set_key(:object_classification, :content_no_metadata)
    end
    ohobj
  end
end