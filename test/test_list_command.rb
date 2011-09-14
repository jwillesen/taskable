require 'cmdparse'
require 'stringio'
require 'test/unit'
require 'taskable'
require 'taskable/commands'

class TestListCommand < Test::Unit::TestCase
  def setup
    @runner = Taskable::Runner.empty_mock
    @list = Taskable::Commands::ListCommand.new(@runner)
    @list.config.format = "csv"
    @list.output = StringIO.new
    @root = @runner.root
  end
  
  def output_lines
    lines = @list.output.string.lines.to_a.drop(1)
    lines.map(&:strip)
  end
  
  def execute
    @list.execute([])
  end
    
  def test_simple_csv_line
    @root.task :test do
      estimate 1
      spent 2
      remaining 3
    end
    execute
    assert_equal(["test,1,2,3"], output_lines)
  end
  
  def test_sub_task_line
    @root.task :test do
      task :sub 
    end
    @root.task :other
    
    @list.execute([])
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
    @list.config.complete = true
    setup_complete_tasks
    execute
    expected = ["complete,,,0", "parent_complete,,,", "parent_complete.child_complete,,,0"]
    assert_equal(expected, output_lines)
  end
  
  def test_incomplete_flag
    @list.config.incomplete = true
    setup_complete_tasks
    execute
    expected = ["incomplete,,,", "parent_incomplete,,,", "parent_incomplete.child_incomplete,,,"]
    assert_equal(expected, output_lines)
  end
  
  def test_need_estimate
    @list.config.need_estimate = true
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
    @list.config.in_progress = true
    @root.instance_exec do
      task(:progress) do
        estimate 3
        spent 1 
      end
      
      task(:no_progress) do
        estimate 3
      end
      
      task(:implicit_complete) do
        estimate 3
        spent 3
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
        rem 10
      end
      
      task :third do
        est 33
      end
      
      task :fourth
      
      task :fifth do
        spent 5
        rem 15
      end
      
      task :sixth do
        rem 20
      end
    end
    execute
    expected = {
      :estimate => 11 + 22 + 33 + 0 + 0 + 0,
      :spent => 3 + 4 + 0 + 0 + 5 + 0,
      :remaining => 8 + 10 + 33 + 0 + 15 + 20,
    }
    assert_equal(expected, @list.totals)
    
  end
  
end
