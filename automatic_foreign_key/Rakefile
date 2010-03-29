# encoding: utf-8
require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "automatic_foreign_key"
    gem.summary = %Q{Automatically generate foreign-key constraints when creating tables}
    gem.description = %Q{Automatic Key Migrations is a gem that automatically generates foreign-key
constraints when creating tables. It uses SQL-92 syntax and as such should be compatible with most databases that support foreign-key constraints.}
    gem.email = "michal.lomnicki@gmail.com"
    gem.homepage = "http://github.com/mlomnicki/automatic_foreign_key"
    gem.authors = ["Michał Łomnicki"]
    gem.add_dependency "redhillonrails_core", ">= 1.0.2"
    gem.add_dependency "activerecord", ">= "2.2"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
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

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "automatic_foreign_key #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
