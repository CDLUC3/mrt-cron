require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ClassifyTask < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
    @categories = @taskdef.fetch(:categorize, [])
    @metadata_types = @taskdef.fetch(:metadata_types, [])
  end

  def category_init(ohobj, cat)
    name = cat.fetch(:name, 'na').to_sym
    ohobj.analysis.zero_subkey(:classification, name)
    ohobj.analysis.set_subkey(:mime_classification, name, [])
    ohobj.analysis.set_key(:metadata_paths, {
      metadata: [],
      common_metadata: [],
      bag_metadata: []
    })
  end

  def test_category(cat, mime, basename)
    categorization = :na
    name = cat.fetch(:name, 'na').to_sym

    cat.fetch(:paths, []).each do |m|
      if m == basename
        categorization = name
        set_metadata_paths(categorization, basename)
        break
      end
    end
    return categorization if categorization != :na

    cat.fetch(:patterns, []).each do |m|
      if basename =~ Regexp.new(m)
        categorization = name
        set_metadata_paths(categorization, basename)
        break
      end
    end
    return categorization if categorization != :na

    cat.fetch(:mimes, {}).keys.each do |m|
      if m == mime
        categorization = name
        set_metadata_paths(categorization, basename)
        break
      end
    end
    return categorization if categorization != :na

    categorization
  end

  def run_task(ohobj)
    ohobj.analysis.zero_subkey(:classification, :na)
    ohobj.analysis.set_subkey(:mime_classification, :na, [])
    @categories.each do |cat|
      category_init(ohobj, cat)
    end

    ohobj.build.get_object.fetch(:producer, []).each do |f|
      mime = f[:mime_type].to_sym
      path = f[:pathname]
      basename = path.split("/")[-1]

      categorization = :na
      @categories.each do |cat|
        categorization = test_category(cat, mime, basename)
        break if categorization != :na
      end
      ohobj.analysis.increment_subkey(:classification, categorization)
      ohobj.analysis.append_subkey(:mime_classification, categorization, mime) unless ohobj.analysis.get_object.fetch(:mime_classification, {}).fetch(categorization, []).include?(mime)
    end

    deterimine_object_classification(ohobj)
    deterimine_metadata_classification(ohobj)
    ohobj.analysis.set_key(:primary_metadata_file, deterimine_primary_metadata_file(ohobj))

    ohobj
  end

  def deterimine_object_classification(ohobj)
    fclass = ohobj.analysis.get_object.fetch(:classification, {})
    omimes = ohobj.analysis.get_object.fetch(:mime_classification, {})

    ohobj.analysis.set_key(:object_classification, :unknown)
    if fclass.fetch(:complex, 0) > 0 || omimes.fetch(:content, []).length > 1
      ohobj.analysis.set_key(:object_classification, :complex_object)
    elsif fclass.fetch(:content, 0) > 1 && fclass.fetch(:derivatives, 0) > 0
      ohobj.analysis.set_key(:object_classification, :multi_digital_files_with_derivatives)
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
  end

  def deterimine_metadata_classification(ohobj)
    fclass = ohobj.analysis.get_object.fetch(:classification, {})
    ohobj.analysis.set_key(:metadata_classification, :unknown)
    mdcount = 0
    @metadata_types.each do |mt|
      mdcount = mdcount + fclass.fetch(mt, 0)
    end
    if mdcount > 1 
      ohobj.analysis.set_key(:metadata_classification, :multi_metadata)
    elsif mdcount == 1 && fclass.fetch(:secondary, 0) > 0
      ohobj.analysis.set_key(:metadata_classification, :metadata_with_secondary)
    elsif mdcount == 1 && fclass.fetch(:secondary, 0) == 0
      ohobj.analysis.set_key(:metadata_classification, :single_metadata_file)
    elsif mdcount == 0 && fclass.fetch(:secondary, 0) > 0
      ohobj.analysis.set_key(:metadata_classification, :secondary_only)
    elsif mdcount == 0 && fclass.fetch(:secondary, 0) == 0
      ohobj.analysis.set_key(:metadata_classification, :no_metadata)
    end
  end

  def deterimine_primary_metadata_file(ohobj)
    @metadata_types.each do |mt|
      arr = ohobj.analysis.get_object.fetch(:metadata_paths, {}).fetch(mt, [])
      next if arr.empty?
      arr.length > 1 ? "Multiple Options: #{arr.length}" : arr[0]
    end
    "NA"
  end

  def set_metadata_paths(categorization, path)
    @metadata_types.each do |mt|
      if categorization == mt
        ohobj.analysis.append_subkey(:metadata_paths, categorization, path)
      end
    end
  end
end