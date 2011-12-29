require_relative 'command_test_helper'

class TestListCommand < Test::Unit::TestCase
  include CommandTestHelper
  
  def create_command
    cmd = Taskable::Commands::ListCommand.new(@runner)
    cmd.config.format = "csv"
    return cmd
  end
  
  def test_simple_csv_line
    @root.task :test do
      estimate 1
      spent 2
      add 4
    end
    execute
    assert_equal(["test,1,2,3"], output_lines)
  end
  
  def test_sub_task_line
    @root.task :test do
      task :sub 
    end
    @root.task :other
    
    execute
    expected = ["test,,,", "test.sub,,,", "other,,,"]
    assert_equal(expected, output_lines)
  end
  
  def setup_complete_tasks
    @root.task(:complete) { complete }
    @root.task(:incomplete)
    
    @root.task(:parent_complete) do
      task(:child_complete) { complete }
    end
    
    @root.task(:parent_incomplete) do
      task(:child_incomplete)
    end
  end
  
  def test_complete_flag
    @command.config.complete = true
    setup_complete_tasks
    execute
    expected = ["complete,,,0", "parent_complete,,,", "parent_complete.child_complete,,,0"]
    assert_equal(expected, output_lines)
  end
  
  def test_incomplete_flag
    @command.config.incomplete = true
    setup_complete_tasks
    execute
    expected = ["incomplete,,,", "parent_incomplete,,,", "parent_incomplete.child_incomplete,,,"]
    assert_equal(expected, output_lines)
  end
  
  def test_need_estimate
    @command.config.need_estimate = true
    @root.instance_exec do
      task(:estimated) { estimate 1 }
      task(:unestimated)
      
      task(:parent_estimated) do
        task(:child_estimated) { estimate 1 }
      end
      
      task(:parent_unestimated) do
        task(:child_unestimated)
      end
    end
    
    execute
    expected = ["unestimated,,,", "parent_unestimated,,,", "parent_unestimated.child_unestimated,,,"]
    assert_equal(expected, output_lines)
  end
  
  def test_in_progress
    @command.config.in_progress = true
    @root.instance_exec do
      task(:progress) do
        estimate 3
        spent 1 
      end
      
      task(:no_progress) do
        estimate 3
      end
      
      task(:explicit_complete) do
        estimate 3
        spent 1
        complete
      end
      
      task(:parent_progress) do
        task(:child_progress) do
          estimate 3
          spent 1
        end
      end
      
      task(:parent_no_progress) do
        task(:child_no_progress) { complete }
      end
      
      task(:parent_complete) do
        task(:child_complete) { complete }
      end
    end
    
    execute
    expected = ["progress,3,1,2", "parent_progress,,,", "parent_progress.child_progress,3,1,2"]
    assert_equal(expected, output_lines)
    
  end
  
  def test_totals
    @root.instance_exec do
      task :first do
        est 11
        spent 3
      end
      
      task :second do
        est 22
        spent 4
        add -8
      end
      
      task :third do
        est 33
      end
      
      task :fourth
      
      task :fifth do
        spent 5
        add 20
      end
      
      task :sixth do
        add 20
      end
    end
    execute
    expected = {
      :estimate => 11 + 22 + 33 + 0 + 0 + 0,
      :spent => 3 + 4 + 0 + 0 + 5 + 0,
      :remaining => 8 + 10 + 33 + 0 + 15 + 20,
    }
    assert_equal(expected, @command.totals)
    
  end
  
  def test_floats
    @root.instance_exec do
      task :a do
        est 1.5
        spent 0.6
      end
      
      task :b do
        est 2.7
        spent 1.3
        add 3.8 + 1.3 - 2.7 # want 3.8 remaining
      end
    end
    execute
    expected = {
      :estimate => 1.5 + 2.7,
      :spent => 0.6 + 1.3,
      :remaining => (1.5 - 0.6) + 3.8,
    }
    assert_equal(expected, @command.totals)
    
    expected = ["a,1.5,0.6,0.9", "b,2.7,1.3,3.8"]
    assert_equal(expected, output_lines)
  end
  
  def test_name_filters
    @root.instance_exec do
      task :abc do
        task :sub
      end
      
      task :def do
        task :sub
      end
    end
    
    execute("abc")
    expected = ["abc,,,", "abc.sub,,,"]
    assert_equal(expected, output_lines)
  end
  
  def test_multiple_filters
    @root.instance_exec do
      task :abc 
      task :def 
      task :ghi 
    end
    
    execute('c', 'e')
    expected = ['abc,,,','def,,,']
    assert_equal(expected, output_lines)
    
  end
  
  
end
