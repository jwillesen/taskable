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
    raise "A task may only have one estimate." if @task.estimate
    @task.estimate = n
  end
  alias est estimate
  
  def add(n)
    @task.additional ||= 0
    @task.additional += n
  end
  
  def spent(n)
    @task.spent ||= 0
    @task.spent += n
  end
  
  def complete()
    @task.complete = true
  end
  alias done complete
  
  def note(str)
    @task.notes << str.to_s
  end
  
end
