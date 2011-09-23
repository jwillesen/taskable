require 'cmdparse'
require 'stringio'
require 'test/unit'
require 'taskable'
require 'taskable/commands'

module CommandTestHelper
  def setup
    @runner = Taskable::Runner.empty_mock
    @command = create_command
    @command.output = StringIO.new
    @root = @runner.root
  end
  
  def output_lines
    lines = @command.output.string.lines.to_a.drop(1)
    lines.map(&:strip)
  end
  
  def execute(*name_filters)
    @command.execute(name_filters)
  end

end
