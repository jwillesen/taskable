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
      remaining 3
      note "note"
      note "second note"
    end
    assert_equal(@root, sub.parent)
    assert_equal("description", sub.description)
    assert_equal(4.0, sub.estimate)
    assert_equal(2.0, sub.spent)
    assert_equal(3.0, sub.remaining)
    assert_equal(2, sub.notes.size)
    assert_equal("note", sub.notes[0])
    assert_equal("second note", sub.notes[1])
  end
  
  def test_complate
    sub = @root.task :sub do
      complete
    end
    assert_equal(0, sub.remaining)
    
  end
  
end
