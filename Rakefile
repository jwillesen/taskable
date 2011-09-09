require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'

require_relative 'lib/taskable/version'
require_relative 'lib/taskable/dependencies'

begin
  require 'yard'
rescue LoadError
end

CLOBBER << "gen"

spec = Gem::Specification.new do |s|
  s.name = "taskable"
  s.summary = "Command line tool and ruby DSL for creating and analyzing task lists for projects."
  #s.description = <<-EOF
  #  Command line interface for analyzing a ruby DSL task list.
  #EOF
  s.version = Taskable::VERSION
  s.author = "Jon Willesen"
  s.email = "git@wizardwell.net"
  s.required_ruby_version = '>= 1.9.2'
  s.files = FileList["lib/**/*.rb", "bin/*", "[A-Z]*", "test/**/*"].to_a
  s.test_files = FileList["test/**/test_*.rb"].to_a
  
  Taskable::Dependencies.each do |d|
    s.add_dependency(*d)
  end
end

Rake::GemPackageTask.new(spec).define

Rake::TestTask.new do |t|
  #t.verbose = true
end
task :default => :test

Rake::RDocTask.new do |rd|
  rd.main = "README.md"
  rd.rdoc_files.include("README.md")
  rd.rdoc_files.include("lib/**/*.rb")
end

if self.class.const_defined? :YARD
  YARD::Rake::YardocTask.new do |yd|
    yd.options = ["--readme", "README.md"]
  end
  CLOBBER.include('doc', '.yardoc')
end
