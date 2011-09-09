module Taskable

class Task
  attr_reader :name
  attr_accessor :subtasks, :parent
  attr_accessor :description, :notes
  attr_accessor :estimate, :spent, :remaining
  
  def initialize(name, parent=nil, &block)
    @name = name.to_s
    @subtasks = []
    @parent = parent
    @description = ""
    @notes = []
    @estimate = nil
    @spent = nil
    @remaining = nil
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
    remaining == 0
  end
  
  def leaf?
    return subtasks.empty?
  end

end

end
