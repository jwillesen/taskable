require 'taskable/runner'

module Taskable
  class <<self
    def run(args)
      runner = Runner.new
      runner.run(args)
    end
  end
end
  
