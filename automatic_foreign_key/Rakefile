# encoding: utf-8
require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "automatic_foreign_key"
    gem.summary = %Q{Automatically generate foreign-key constraints when creating tables}
    gem.description = %Q{Automatic Foreign Key automatically generates foreign-key
constraints when creating tables or adding columns. It uses SQL-92 syntax and as such should be compatible with most databases that support foreign-key constraints.}
    gem.email = "michal.lomnicki@gmail.com"
    gem.homepage = "http://github.com/mlomnicki/automatic_foreign_key"
    gem.authors = ["Michał Łomnicki"]
    gem.add_dependency "redhillonrails_core", ">= 1.0.4.1"
    gem.add_dependency "activerecord", ">= 2.2"
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

require 'spec/rake/spectask'
%w[postgresql mysql mysql2].each do |adapter|
  namespace adapter do
    Spec::Rake::SpecTask.new(:spec) do |spec|
      spec.libs << 'lib' << 'spec' << "spec/connections/#{adapter}"
      spec.spec_files = FileList['spec/**/*_spec.rb']
    end
  end
end

desc 'Run postgresql and mysql tests'
task :spec do 
  %w[postgresql mysql mysql2].each do |adapter|
    Rake::Task["#{adapter}:spec"].invoke
  end
end

task :spec => :check_dependencies

task :default => :spec

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "automatic_foreign_key #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :postgresql do
  desc 'Build the PostgreSQL test databases'
  task :build_databases do
    %x( createdb -E UTF8 afk_unittest )
    %x( createdb -E UTF8 afk_unittest2 )
  end

  desc 'Drop the PostgreSQL test databases'
  task :drop_databases do
    %x( dropdb afk_unittest )
    %x( dropdb afk_unittest2 )
  end

  desc 'Rebuild the PostgreSQL test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]
end

task :build_postgresql_databases => 'postgresql:build_databases'
task :drop_postgresql_databases => 'postgresql:drop_databases'
task :rebuild_postgresql_databases => 'postgresql:rebuild_databases'

MYSQL_DB_USER = 'afk'
namespace :mysql do
  desc 'Build the MySQL test databases'
  task :build_databases do
    %x( echo "create DATABASE afk_unittest DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci " | mysql --user=#{MYSQL_DB_USER})
  end

  desc 'Drop the MySQL test databases' 
  task :drop_databases do
    %x( mysqladmin --user=#{MYSQL_DB_USER} -f drop afk_unittest )
  end

  desc 'Rebuild the MySQL test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]
end

task :build_mysql_databases => 'mysql:build_databases'
task :drop_mysql_databases => 'mysql:drop_databases'
task :rebuild_mysql_databases => 'mysql:rebuild_databases'
