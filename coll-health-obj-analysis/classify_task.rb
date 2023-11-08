require 'json'
require 'mustache'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ClassifyTask < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
    @catmap = {}
    @categories = @taskdef.fetch(:categorize, [])
    @metadata_types = @taskdef.fetch(:metadata_types, [])
  end

  def category_init(ohobj, cat)
    name = cat.fetch(:name, 'na').to_sym
    @catmap[name] = cat
    ohobj.analysis.zero_subkey(:classification, name)
    ohobj.analysis.set_subkey(:mime_file_classification, name, [])
    @metadata_types.keys.each do |mt|
      ohobj.analysis.set_subkey(:metadata_paths, mt, [])
    end
  end

  def test_category(cat, mime, basename, ohobj)
    name = cat.fetch(:name, 'na').to_sym

    if ObjectHealth.match_criteria(criteria: cat, key: basename, ohobj: ohobj, criteria_list: :paths, criteria_templates: :templates, criteria_patterns: :patterns)
      set_metadata_paths(name, basename, ohobj)
      return name
    end

    if ObjectHealth.match_criteria(criteria: cat, key: mime, ohobj: ohobj, criteria_list: :mimes)
      set_metadata_paths(name, basename, ohobj)
      return name
    end

    if mime.to_s =~ %r[;]
      tmime = mime.to_s.split(";")[0]
      if ObjectHealth.match_criteria(criteria: cat, key: tmime, ohobj: ohobj, criteria_list: :mimes)
        set_metadata_paths(name, basename, ohobj)
        return name
      end
    end  
    :na
  end

  def run_task(ohobj)
    ohobj.analysis.zero_subkey(:classification, :na)
    ohobj.analysis.set_subkey(:mime_file_classification, :na, [])
    @categories.each do |cat|
      category_init(ohobj, cat)
    end

    ohobj.build.get_object.fetch(:producer, []).each do |f|
      mime = f[:mime_type].to_sym
      path = f[:pathname]
      basename = path.split("/")[-1]

      categorization = :na
      @categories.each do |cat|
        categorization = test_category(cat, mime, basename, ohobj)
        break if categorization != :na
      end
      ohobj.analysis.increment_subkey(:classification, categorization)
      unless ohobj.analysis.get_object.fetch(:mime_file_classification, {}).fetch(categorization, []).include?(mime)
        ohobj.analysis.append_subkey(:mime_file_classification, categorization, mime) 
      end
      if categorization == :na
        ohobj.analysis.append_key(:unclassified_mime_files, {path: path, mime: mime})
      end
    end

    deterimine_object_classification(ohobj)
    deterimine_metadata_classification(ohobj)
    ohobj.analysis.set_key(:primary_metadata_file, deterimine_primary_metadata_file(ohobj))

    ohobj
  end

  def count_complex(ohobj)
    fclass = ohobj.analysis.get_object.fetch(:classification, {})
    fclass.fetch(:complex, 0)
  end

  def count_distinct_mimes(ohobj)
    omimes = ohobj.analysis.get_object.fetch(:mime_file_classification, {})
    omimes.fetch(:content, []).length
  end

  def count_content_files(ohobj)
    fclass = ohobj.analysis.get_object.fetch(:classification, {})
    fclass.fetch(:content, 0)
  end

  def count_derivative_files(ohobj)
    fclass = ohobj.analysis.get_object.fetch(:classification, {})
    fclass.fetch(:derivatives, 0)
  end

  def deterimine_object_classification(ohobj)
    ohobj.analysis.set_key(:object_classification, :unknown)
    if count_complex(ohobj) > 0 || count_distinct_mimes(ohobj) > 1
      ohobj.analysis.set_key(:object_classification, :complex_object)
    elsif count_content_files(ohobj) > 1 && count_derivative_files(ohobj) > 0
      ohobj.analysis.set_key(:object_classification, :has_multi_digital_files_with_derivatives)
    elsif count_content_files(ohobj) > 1 
      ohobj.analysis.set_key(:object_classification, :has_multi_digital_files)
    elsif count_content_files(ohobj) == 1 && count_derivative_files(ohobj) > 0
      ohobj.analysis.set_key(:object_classification, :has_digital_file_with_derivatives)
    elsif count_content_files(ohobj) == 0 && count_derivative_files(ohobj) > 0
      ohobj.analysis.set_key(:object_classification, :has_derivatives_only)
    elsif count_content_files(ohobj) == 1 
      ohobj.analysis.set_key(:object_classification, :has_single_digital_file)
    elsif count_content_files(ohobj) == 0 
      ohobj.analysis.set_key(:object_classification, :has_no_content)
    end
  end

  def count_metadata_files(ohobj)
    fclass = ohobj.analysis.get_object.fetch(:classification, {})
    fclass.fetch(:metadata, 0)
  end

  def count_common_metadata_files(ohobj)
    fclass = ohobj.analysis.get_object.fetch(:classification, {})
    fclass.fetch(:common_metadata, 0)
  end

  def count_bag_metadata_files(ohobj)
    fclass = ohobj.analysis.get_object.fetch(:classification, {})
    fclass.fetch(:bag_metadata, 0)
  end

  def count_etd_metadata_files(ohobj)
    fclass = ohobj.analysis.get_object.fetch(:classification, {})
    fclass.fetch(:etd_metadata, 0)
  end

  def count_nuxeo_metadata_files(ohobj)
    fclass = ohobj.analysis.get_object.fetch(:classification, {})
    fclass.fetch(:nuxeo_style_metadata, 0)
  end

  def count_secondary_metadata_files(ohobj)
    fclass = ohobj.analysis.get_object.fetch(:classification, {})
    fclass.fetch(:secondary, 0)
  end

  def deterimine_metadata_classification(ohobj)
    if count_common_metadata_files(ohobj) > 0
      ohobj.analysis.set_key(:metadata_classification, :has_common_metadata_file)
    elsif count_bag_metadata_files(ohobj) > 0
      ohobj.analysis.set_key(:metadata_classification, :has_bag_metadata_file)
    elsif count_etd_metadata_files(ohobj) > 0 
      ohobj.analysis.set_key(:metadata_classification, :has_etd_metadata_file)
    elsif count_nuxeo_metadata_files(ohobj) > 0
      ohobj.analysis.set_key(:metadata_classification, :has_nuxeo_style_metadata_file)
    elsif count_metadata_files(ohobj) > 1 
      ohobj.analysis.set_key(:metadata_classification, :has_multi_metadata)
    elsif count_metadata_files(ohobj) == 1 && count_secondary_metadata_files(ohobj) > 0
      ohobj.analysis.set_key(:metadata_classification, :has_metadata_with_secondary)
    elsif count_metadata_files(ohobj) == 1 && count_secondary_metadata_files(ohobj) == 0
      ohobj.analysis.set_key(:metadata_classification, :has_single_metadata_file)
    elsif count_metadata_files(ohobj) == 0 && count_secondary_metadata_files(ohobj) > 0
      ohobj.analysis.set_key(:metadata_classification, :has_secondary_metadata_only)
    elsif count_metadata_files(ohobj) == 0 && count_secondary_metadata_files(ohobj) == 0
      ohobj.analysis.set_key(:metadata_classification, :has_no_sidecar_metadata)
    end
  end

  def deterimine_primary_metadata_file(ohobj)
    @metadata_types.keys.each do |mt|
      arr = ohobj.analysis.get_object.fetch(:metadata_paths, {}).fetch(mt, [])
      next if arr.empty?
      return arr[0] if arr.length == 1
      return "Multiple Options: #{arr.length}" if mt == :metadata
      cat = @catmap[mt]
      return ObjectHealth.match_first(cat.fetch(:paths, []), arr) if cat.fetch(:ordered_paths, false)
      return arr[0]
    end
    :NA
  end

  def set_metadata_paths(categorization, path, ohobj)
    return if path == :NA
    return unless ohobj.analysis.get_object.fetch(:metadata_paths, {}).key?(categorization)
    ohobj.analysis.append_subkey(:metadata_paths, categorization, path)
  end
end