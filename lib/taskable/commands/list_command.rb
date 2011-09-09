module Taskable::Commands
  class ListCommand < CmdParse::Command
    
    Config = Struct.new(
      :complete, :incomplete, :need_estimate, :in_progress, :name_only
      )

    attr_accessor :config
    
    def initialize(runner)
      super('list', false)
      
      @runner = runner
      @config = Config.new
      @filter = nil
      
      self.short_desc = "List specified tasks"
      self.description = "List the tasks as specified by command line parameters"
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.on("-c", "--complete", "Show complete tasks") { config.complete = true }
        opts.on("-i", "--incomplete", "Show incomplete tasks") { config.incomplete = true }
        opts.on("-n", "--need-estimate", "Show tasks that don't have estimates") { config.need_estimate = true }
        opts.on("-p", "--in-progress", "Show tasks in progress") { config.in_progress = true }
      end
    end
    
    def execute(args)
      filtered_tasks = filter_tasks(@runner.root)
      filtered_tasks.each do |task|
        puts task.name
      end
    end
    
    def filter_tasks(task)
      task.subtasks.reduce([]) do |list, subtask|
        if subtask.leaf? && passes_filter(subtask)
          list << subtask
        elsif !subtask.leaf?
          sublist = filter_tasks(subtask)
          sublist.unshift(subtask) if !sublist.empty?
          list + sublist
        else
          list
        end
      end
    end
    
    def passes_filter(task)
      init_filter_from_options
      return @filter[task]
    end
    
    def init_filter_from_options
      @filter ||= case
        when config.complete then lambda { |t| t.complete? }
        when config.incomplete then lambda { |t| !t.complete? }
        when config.need_estimate then lambda { |t| t.estimate.nil? && !t.complete?}
        when config.in_progress then lambda { |t| !t.spent.nil? && t.spent > 0 && !t.complete? }
        else lambda {|t| true}
      end
    end
    
  end
end
