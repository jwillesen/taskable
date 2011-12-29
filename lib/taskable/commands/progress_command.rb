module Taskable::Commands
  class ProgressCommand < CmdParse::Command
    
    Config = Struct.new(
      :show_error, :hours_per_day, :show_days, :format
      )
    
    ValidFormats = %w(pretty csv)
    
    DefaultHoursPerDay = 8
    
    attr_accessor :config, :output

    
    def initialize(runner)
      super('progress', false)
      @runner = runner
      @config = Config.new
      @output = $stdout
      
      @total_estimate = 0
      @total_spent = 0
      @total_remaining = 0
      
      self.short_desc = "Show progress summary"
      self.description = "Show the overall progress summary."
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.on('-e', '--estimate-error', "Include the current estimate error.") do
          config.show_error = true
        end
        
        opts.on('-d', '--days', "Display the progress in terms of days instead of hours.") do
          config.show_days = true
        end
        
        opts.on('-h', '--hours-per-day HOURS', Integer,
          "Set the number of hours per day (default #{DefaultHoursPerDay}).") do |hours|
          config.hours_per_day = hours
        end
        
        opts.on("--format FMT", "Set output format: #{ValidFormats.join(', ')}") do |value|
          config.format = value.downcase
        end
        
      end
    end
    
    def validate_options
      # defaults
      config.format ||= ValidFormats[0]
      config.hours_per_day ||= DefaultHoursPerDay
      
      raise "Invalid format: #{config.format}" unless ValidFormats.include?(config.format)
      raise "Invalid argument: #{config.hours_per_day}" unless config.hours_per_day > 0
    end
    
    def execute(args)
      begin
        validate_options
      rescue
        @output.puts $!
        exit 1
      end
      
      @total_estimate, @total_spent, @total_remaining = *calculate_totals(@runner.root)
      convert_to_days() if config.show_days
      format_totals()
    end
    
    def calculate_totals(task)
      task.subtasks.reduce(Vector[0, 0, 0]) do |totals, subtask|
        [
          totals,
          Vector[subtask.estimate.to_f, subtask.spent.to_f, subtask.remaining.to_f],
          calculate_totals(subtask),
        ].reduce(:+)
      end
    end
    
    def convert_to_days()
      @total_estimate /= config.hours_per_day.to_f
      @total_spent /= config.hours_per_day.to_f
      @total_remaining /= config.hours_per_day.to_f
    end
    
    def percent_complete
      return '0' if @total_spent == 0 && @total_remaining == 0
      decimal = @total_spent.to_f / (total_project.to_f)
      percent = (decimal * 100).round.to_s
    end
    
    def total_project
      @total_spent + @total_remaining
    end
    
    def format_totals()
      self.send("format_totals_#{config.format}")
    end
    
    def format_totals_pretty()
      @output.puts "#{@total_spent} of #{total_project} (#{percent_complete}%)"
    end
    
    def format_totals_csv()
      @output.puts %w(spent,total).join(',')
      @output.puts [@total_spent, total_project].join(',')
    end
    
  end
end
