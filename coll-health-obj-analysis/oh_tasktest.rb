require 'json'

class ObjHealthTask
  def initialize(oh, taskdef, name)
    @oh = oh
    @taskdef = taskdef
    scope = @taskdef.fetch(:collection_scope, {})
    @skip = scope.fetch(:skip, [])
    @apply = scope.fetch(:apply, [])
    @name = name
  end

  def check_scope(ohobj)
    m = ohobj.mnemonic
    colltax = @oh.collection_taxonomy(m)
    if @apply.length > 0
      return @apply.include?(m) || @apply.include(colltax)
    elsif @skip.length > 0
      return !(@skip.include?(m) || @skip.include?(colltax))
    end
    true
  end

  def name
    @name
  end
  
  def self.create(oh, taskdef, name)
    unless taskdef.nil?
      taskclass = taskdef.fetch(:class, '')
      unless taskclass.empty?
        Object.const_get(taskclass).new(oh, taskdef, name)
      end
    end
  end

  def run_task(ohobj)
    ohobj.analysis
  end

  def self.match_first(ordered_list, list_set)
    ordered_list.each do |v|
      return v if list_set.include?(v)
    end
    return nil
  end

  def self.match_list(list, str)
    list.include?(str)
  end

  def self.match_map(map, str)
    self.match_list(map.keys, str)
  end

  def self.match_template_list(list, str, ohobj)
    tlist = []
    list.each do |v|
      tlist.append(Mustache.render(v, ohobj.template_map))
    end
    self.match_list(tlist, str)
  end

  def self.match_pattern(list, str)
    list.each do |v|
      return true if str =~ Regexp.new(v)
    end
    false
  end

  def inspect
    self.to_s
  end

end

class ObjHealthTest < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def run_test(ohobj)
    :SKIP
  end
end