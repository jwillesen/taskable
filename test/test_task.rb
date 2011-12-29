require 'test/unit'
require 'taskable'

class TestTask < Test::Unit::TestCase
  def setup
    @root = Taskable::Task.new :root
  end
  
  def teardown
    @root = nil
  end
  
  def test_subtask
    assert(@root.subtasks.empty?)
    sub = @root.task :sub
    assert_equal(1, @root.subtasks.size)
    assert_equal(@root.subtasks[0], sub)
    assert_equal(@root, sub.parent)
    assert_equal("sub", sub.name)
  end
  
  def test_subtask_block
    sub = @root.task :sub do
      desc "description"
      estimate 4
      spent 2
      spent 3
      add 3
      add 1
      
      note "note"
      note "second note"
    end
    assert_equal(@root, sub.parent)
    assert_equal("description", sub.description)
    assert_equal(4.0, sub.estimate)
    assert_equal(4.0, sub.additional)
    assert_equal(5.0, sub.spent)
    assert_equal(3.0, sub.remaining)
    assert_equal(2, sub.notes.size)
    assert_equal("note", sub.notes[0])
    assert_equal("second note", sub.notes[1])
  end
  
  def test_set_complete
    sub = @root.task :sub do
      complete
    end
    assert_equal(0, sub.remaining)
  end
  
  def test_full_name
    sub = @root.task :sub
    marine = sub.task :marine
    assert_equal("sub.marine", marine.full_name)
  end
  
  def test_remaining
    sub = @root.task :sub 
    assert_equal(nil, sub.remaining)
    
    sub.spent = 3
    assert_equal(nil, sub.remaining)
    
    sub.estimate = 5
    assert_equal(2, sub.remaining)
    
    sub.spent = nil
    assert_equal(5, sub.remaining)
    
    sub.additional = 7
    assert_equal(7 + 5, sub.remaining)
    
    sub.spent = 5
    assert_equal(7, sub.remaining)
    
    sub.estimate = nil
    assert_equal(2, sub.remaining)
    
    sub.spent = nil
    assert_equal(7, sub.remaining)
  end
  
  def test_overspent
    sub = @root.task :sub do
      estimate 4
      spent 6
    end
    assert_equal(0, sub.remaining)
  end
  
  def test_complete?
    sub = @root.task :sub do
      estimate 3
      spent 1
    end
    
    assert_equal(false, sub.complete?)
    sub.spent = sub.estimate
    assert_equal(false, sub.complete?)
    sub.spent -= 1
    sub.complete = true
    assert_equal(true, sub.complete?)
  end
  
  def test_multi_estimate
    assert_raise(RuntimeError) do
      sub = @root.task :sub do
        est 1
        est 2
      end
    end
  end
  
end
