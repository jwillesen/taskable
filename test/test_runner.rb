require 'cmdparse'
require 'fileutils'
require 'test/unit'
require 'taskable'
require 'taskable/commands'

class TestRunner < Test::Unit::TestCase
  include FileUtils
  
  def setup
    mkdir_p("gen/test")
    touch("gen/test/Taskfile")
  end
  
  def teardown
    rm_rf("gen/test")
  end
  
  def test_find_taskfile_this_dir
    taskfile_path = "#{pwd}/gen/test/Taskfile"
    cd "gen/test" do
      runner = Taskable::Runner.new
      assert_equal(taskfile_path, runner.find_taskfile)
      assert_equal(taskfile_path, runner.taskfile)
    end
  end
  
  def test_fail_find_taskfile
    runner = Taskable::Runner.new
    runner.potential_taskfiles = ["ThisDoesNotExist"]
    assert_equal(nil, runner.find_taskfile)
    assert_raises(RuntimeError) { runner.taskfile }
  end
  
  
  
end
