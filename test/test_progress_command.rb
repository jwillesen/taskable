require_relative 'command_test_helper'

class TestProgressCommand < Test::Unit::TestCase
  include CommandTestHelper
  
  def create_command
    cmd = Taskable::Commands::ProgressCommand.new(@runner)
    cmd.config.format = 'csv'
    return cmd
  end
  
  def test_empty
    execute
    assert_equal(['0,0'], output_lines)
    assert_equal('0', @command.percent_complete)
  end
  
  def test_simple
    @root.instance_exec do
      task :a do
        est 3.1
        spent 2.1
        rem 1.1
      end
      
      task :b do
        est 10.3
        spent 4.3
        rem 6.3
      end
    end
    execute
    expected = ["6.4,13.8"]
    assert_equal(expected, output_lines)
  end

  def test_recursive
    @root.instance_exec do
      task :t1 do
        task :a do
          est 2
          spent 1
        end
        
        task :b do
          spent 2
          rem 3
        end
      end
      
      task :t2 do
        task :a do
          est 4
        end
      
        task :b do
          spent 5
          rem 6
        end
      end
    end
    execute
    expected = ["8.0,22.0"]
    assert_equal(expected, output_lines)
  end

  def test_days
    @command.config.show_days = true
    @command.config.hours_per_day = 4
    @root.instance_exec do
      task :t1 do
        est 24
        spent 8
      end
    end
    execute
    expected = ["2.0,6.0"]
    assert_equal(expected, output_lines)
  end

end
