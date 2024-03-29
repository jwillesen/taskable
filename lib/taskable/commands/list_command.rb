module Taskable::Commands
  class ListCommand < CmdParse::Command
    
    DefaultIndent = 4
    
    Config = Struct.new(
      :complete, :incomplete, :need_estimate, :in_progress, :name_only, :format
      )

    Column = Struct.new(
      :name, :just, :width, :field
      )
    DefaultColumns = [
      Column["name", :ljust, 40, :name],
      Column["estimate", :rjust, 10, :estimate],
      Column["spent", :rjust, 10, :spent],
      Column["remaining", :rjust, 10, :remaining],
      ]

    ValidFormats = %w(pretty csv)
    
    attr_accessor :config, :output
    attr_reader :total_estimate, :total_spent, :total_remaining, :name_filters
    
    def initialize(runner)
      super('list', false)
      
      @runner = runner
      @config = Config.new
      @output = $stdout
      @filter = nil
      @name_filters = []
      
      @total_estimate = @total_spent = @total_remaining = 0
      
      self.short_desc = "List specified tasks"
      self.description = "List the tasks as specified by command line parameters"
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.on("-c", "--complete", "Show complete tasks") { config.complete = true }
        opts.on("-i", "--incomplete", "Show incomplete tasks") { config.incomplete = true }
        opts.on("-n", "--need-estimate", "Show tasks that don't have estimates") { config.need_estimate = true }
        opts.on("-p", "--in-progress", "Show tasks in progress") { config.in_progress = true }
        opts.on("--format FMT", "Set output format: #{ValidFormats.join(', ')}") { |value| config.format = value.downcase } 
      end
    end
      
    def validate_options(args)
      config.format ||= ValidFormats[0]
      
      @name_filters = args.map { |arg| Regexp.compile(arg) }
      
      raise "Invalid format: #{config.format}" unless ValidFormats.include?(config.format)
      raise "Conflicting completion flags" if config.complete && config.incomplete
    end
    
    def execute(args)
      
      begin
        validate_options(args)
      rescue
        @output.puts $!
        exit 1
      end
      
      filtered_tasks = filter_tasks(@runner.root)
      self.send("print_format_#{config.format}", filtered_tasks)
    end
    
    def print_format_pretty(tasks)
      print_pretty_hr()
      print_pretty_header()
      print_pretty_hr()
      print_pretty_tasks(tasks)
      print_pretty_hr()
      print_pretty_totals()
      print_pretty_hr()
    end
    
    def print_format_csv(tasks)
      @output.puts DefaultColumns.map(&:name).join(',')
      print_csv_tasks(tasks)
    end
    
    def print_csv_tasks(tasks)
      tasks.flatten.each do |task|
        line = DefaultColumns.reduce([]) do |fields, col|
          field_name = col.field
          field_name = :full_name if field_name == :name
          fields << task.public_send(field_name).to_s
        end
        @output.puts line.join(',')
      end
    end
    
    def print_pretty_header
      titles = DefaultColumns.reduce([]) do |titles, col|
        title = col.name
        title = title.public_send(col.just, col.width)
        titles << title
      end
      #divider = titles.map { |title| '-' * title.size }.join('-+')
      titles = titles.join(' |')
      #@output.puts titles, divider
      @output.puts titles
    end
    
    def print_pretty_hr
      divider = DefaultColumns.map { |col| '-' * col.width}.join('-+')
      @output.puts divider
    end
    
    def print_pretty_totals
      fields = DefaultColumns.map do |col|
        case col.name
        when 'name' then 'totals: '
        when 'estimate' then @total_estimate.to_s
        when 'spent' then @total_spent.to_s
        when 'remaining' then @total_remaining.to_s
        else '<unknown>'
        end
      end
      @output.puts format_line(fields)
    end
    
    def print_pretty_tasks(tasks, depth=0)
      tasks.each do |elt|
        case elt
        when Taskable::Task then @output.puts format_task_line(depth, elt)
        when Array then print_pretty_tasks(elt, depth + 1)
        #else ???
        end
      end
      
    end
    
    def format_task_line(depth, task)
      indent = " " * DefaultIndent * depth
      fields = DefaultColumns.map do |col|
        field = task.public_send(col.field).to_s
        field = indent + field if col.name == 'name'
        field
      end
      return format_line(fields)
    end
    
    def format_line(fields)
      padded_fields = DefaultColumns.zip(fields).map do |col, field|
          field.public_send(col.just, col.width)
      end
      return padded_fields.join(' |')
    end
    
    def filter_tasks(task)
      task.subtasks.reduce([]) do |list, subtask|
        if subtask.leaf? && passes_filter(subtask)
          @total_estimate += subtask.estimate.to_f
          @total_spent += subtask.spent.to_f
          @total_remaining += subtask.remaining.to_f
          list << subtask
        elsif !subtask.leaf?
          sublist = filter_tasks(subtask)
          sublist.empty? ? list : (list << subtask << sublist)
        else
          list
        end
      end
    end
    
    def passes_filter(task)
      init_filter_from_options
      return passes_name_filter(task) && @filter[task]
    end
    
    def passes_name_filter(task)
      fn = task.full_name
      @name_filters.empty? || @name_filters.any? { |filter| filter.match(fn) } 
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
    
    def totals()
      return {
        :estimate => @total_estimate,
        :spent => @total_spent,
        :remaining => @total_remaining,
      }
    end
    
  end
end
