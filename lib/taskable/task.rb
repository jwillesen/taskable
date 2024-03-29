module Taskable

class Task
  attr_reader :name
  attr_accessor :subtasks, :parent
  attr_accessor :description, :notes
  attr_accessor :estimate, :spent, :additional
  attr_accessor :complete
  
  def initialize(name, parent=nil, &block)
    @name = name.to_s
    @subtasks = []
    @parent = parent
    @description = ""
    @notes = []
    @estimate = nil
    @spent = nil
    @additional = nil
    @complete = false
    Taskable::TaskDsl.new(self, &block) if block
  end
  
  def name=(str)
    # accept other things, like symbols, but ensure name is stored as a string
    @name = str.to_s
  end
  
  def task(sub_name, &block)
    sub = Task.new(sub_name, self, &block)
    @subtasks << sub
    return sub
  end
  
  def complete?
    @complete
  end
  
  def leaf?
    return subtasks.empty?
  end
  
  def full_name
    lineage = []
    cur = self
    until cur.nil? || cur.name == Taskable::RootName
      lineage.unshift(cur.name)
      cur = cur.parent
    end
    return lineage.join('.')
  end

  def remaining
    return 0 if complete?
    return nil if !(estimate || additional)
    calced = (estimate || 0) + (additional || 0) - (spent || 0)
    return [calced, 0].max
  end

end

end
