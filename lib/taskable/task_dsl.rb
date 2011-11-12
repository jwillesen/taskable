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
  alias est estimate
  
  def spent(n)
    @task.spent ||= 0
    @task.spent += n
  end
  
  def remaining(n)
    @task.remaining = n
  end
  alias rem remaining
  
  def complete()
    @task.remaining = 0
  end
  alias done complete
  
  def note(str)
    @task.notes << str.to_s
  end
  
end
