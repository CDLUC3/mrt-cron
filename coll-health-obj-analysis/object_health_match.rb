class ObjectHealthMatch
  def self.match_first(ordered_list, list_set)
    ordered_list.each do |v|
      return v if list_set.include?(v)
    end
    return nil
  end

  def self.match_list(list, str)
    return false if list.nil?
    list.include?(str)
  end

  def self.match_map(map, str)
    return false if map.nil?
    self.match_list(map.keys, str)
  end

  def self.match_template_list(list, str, ohobj)
    return false if list.nil?

    tlist = []
    list.each do |v|
      tlist.append(Mustache.render(v, ohobj.nil? ? {} : ohobj.template_map))
    end
    self.match_list(tlist, str)
  end

  def self.match_pattern(list, str)
    return false if list.nil?

    list.each do |v|
      return true if str =~ Regexp.new(v)
    end
    false
  end

  def self.match_criteria(criteria:, key:, ohobj:, criteria_list: nil, criteria_keys: nil, criteria_templates: nil, criteria_patterns: nil)
    return false if criteria.nil?
    b = false
    b = b || self.match_list(criteria.fetch(criteria_list, []), key) if criteria_list
    b = b || self.match_map(criteria.fetch(criteria_keys, []), key) if criteria_keys
    b = b || self.match_pattern(criteria.fetch(criteria_patterns, []), key) if criteria_patterns
    b = b || self.match_template_list(criteria.fetch(criteria_templates, []), key, ohobj) if criteria_templates
    b
  end

  def self.make_status_key_map(criteria, key) 
    mapping = {}
    criteria.fetch(key, {}).each do |k,list|
      next if list.nil?
      list.keys.each do |v|
        mapping[v.to_sym] = k
      end
    end
    mapping
  end
end
