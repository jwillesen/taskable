class Taskable::TaskDsl
  def initialize(task, &block)
    @task = task
    self.instance_exec(&block) if block
  end
  
  def task(*args, &block)
    @task.task(*args, &block)
  end
  
  def description(str)
    @task.description = str.to_s
  end
  alias desc description
  
  def estimate(n)
    @task.estimate = n
  end
  
  def spent(n)
    @task.spent = n
  end
  
  def remaining(n)
    @task.remaining = n
  end
  
  def complete()
    @task.remaining = 0
  end
  
  def note(str)
    @task.notes << str.to_s
  end
  
end
