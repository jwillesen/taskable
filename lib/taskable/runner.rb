here = File.dirname(__FILE__)
command_dir = File.join(here, "commands")
Dir["#{command_dir}/*"].each do |command_file|
  base = File.basename(command_file, '.*')
  str = "taskable/commands/#{base}"
  require str
end

module Taskable
  class Runner
    
    def self.empty_mock
      mock = Runner.new
      mock.taskfile = "empty_mock"
      mock.root = Taskable::Task.new(Taskable::RootName)
      return mock
    end
    
    attr_writer :taskfile, :root
    attr_accessor :original_dir
    attr_accessor :config
    attr_accessor :potential_taskfiles
    
    RootName = "root"
    
    def initialize()
      @taskfile = nil
      @root = nil
      @original_dir = Dir.pwd
      @config = {}
      @potential_taskfiles = ['Taskfile']
      @cmd = create_parser()
    end
    
    def create_parser
      cmd = CmdParse::CommandParser.new(true, true)
      cmd.program_name = "task"
      cmd.program_version = Taskable::VERSION.split('.')
      cmd.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator "Global options:"
        opts.on("--verbose", "Verbose output") { @verbose = true }
        opts.on("-f", "--file FILE", "Input file (by default, searches for Taskfile)") { |f| @taskfile = f }
      end
      cmd.add_command(CmdParse::HelpCommand.new)
      cmd.add_command(CmdParse::VersionCommand.new)
      
      cmd.add_command(Taskable::Commands::ListCommand.new(self))
      
      return cmd
    end
    
    def run(args)
      begin
        @cmd.parse(args)
      rescue
        $stderr.puts($!)
        exit 1
      end
    end
    
    def root
      @root ||= parse_taskfile
    end
    
    def taskfile
      @taskfile ||= find_taskfile
      raise "Taskfile not found" unless @taskfile
      @taskfile
    end
    
    def parse_taskfile
      root_task = Taskable::Task.new(Taskable::RootName)
      # The magic incantations to get the DSL working at the top level
      dsl = TaskDsl.new(root_task)
      dsl.instance_eval(File.read(taskfile), taskfile)
      return root_task
    end
    
    def find_taskfile
      here = Dir.pwd
      while !(fn = dir_has_taskfile(here))
        parent = File.dirname(here)
        return nil if here == parent
        here = parent
      end
      return File.join(here, fn)
    end
    
    def dir_has_taskfile(dir)
      @potential_taskfiles.each do |fn|
        if File.exist?(File.join(dir, fn))
          others = Dir.glob(fn, File::FNM_CASEFOLD)
          return others.size == 1 ? others.first : fn
        end
      end
      return nil
    end
    
  end  
end
