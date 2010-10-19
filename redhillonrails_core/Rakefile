# encoding: utf-8
require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "redhillonrails_core"
    gem.summary = %Q{RedHill on Rails Core is a plugin that features to support other RedHill on Rails plugins}
    gem.description = %Q{RedHill on Rails Core is a plugin that features to support other RedHill on Rails plugins. It creates and drops views and foreign-keys or obtains indexes directly from a model class.}
    gem.email = "michal.lomnicki@gmail.com"
    gem.homepage = "http://github.com/mlomnicki/redhillonrails_core"
    gem.authors = ["Michał Łomnicki"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings

    gem.add_dependency "activerecord", "< 3.0.0"

    gem.add_development_dependency "micronaut"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "redhillonrails_core #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require "micronaut/rake_task"
Micronaut::RakeTask.new(:examples) do |examples|
  examples.pattern = "spec/**/*_spec.rb"
  examples.ruby_opts << "-Ilib -Ispec"
end

Micronaut::RakeTask.new(:rcov) do |examples|
  examples.pattern = "spec/**/*_spec.rb"
  examples.rcov_opts = "-Ilib -Ispec"
  examples.rcov = true
end

task :examples => :check_dependencies

task :default => :examples

namespace :postgresql do
  task :examples do
    ENV["ADAPTER"] = "postgresql"
    Rake::Task["examples"].invoke
  end
end
