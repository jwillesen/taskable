here = File.dirname(__FILE__)
command_dir = File.join(here, "commands")
Dir["#{command_dir}/*"].each do |command_file|
  base = File.basename(command_file, '.*')
  str = "taskable/commands/#{base}"
  require str
end

module Taskable
  class Runner
    attr_accessor :taskfile, :original_dir
    attr_accessor :options
    attr_accessor :root
    attr_accessor :potential_taskfiles
    
    RootName = "root"
    
    def initialize()
      @cmd = create_parser()
      @original_dir = Dir.pwd
      @options = {}
      @root = Task.new(RootName)
      @potential_taskfiles = ['Taskfile']
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
      if !find_taskfile
        $stderr.puts "Could not find Taskfile"
        exit 1
      end
      
      # The magic incantations to get the DSL working at the top level
      dsl = TaskDsl.new(root)
      dsl.instance_eval(File.read(taskfile), taskfile)
      
      @cmd.parse(args)
    end
    
    def find_taskfile
      return @taskfile if @taskfile
      
      here = Dir.pwd
      while !(fn = dir_has_taskfile(here))
        parent = File.dirname(here)
        return nil if here == parent
        here = parent
      end
      @taskfile = File.join(here, fn)
      return @taskfile
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
