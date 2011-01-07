# encoding: utf-8
require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "redhillonrails_core"
    gem.summary = %Q{Adds support in ActiveRecord for foreign_keys, complex indexes and other database-related stuff}
    gem.description = %Q{Adds support in ActiveRecord for foreign_keys, complex indexes and other database-related stuff. Easily create foreign_keys, complex indexes and views.}
    gem.email = "michal.lomnicki@gmail.com"
    gem.homepage = "http://github.com/mlomnicki/redhillonrails_core"
    gem.authors = ["Michał Łomnicki"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings

    gem.add_dependency "activerecord"

    gem.files.exclude ".gitignore"
    gem.files.exclude ".document"
    gem.files.exclude ".rvmrc"
    gem.files.exclude "Gemfile"
    gem.files.exclude "Gemfile.lock"
    gem.files.exclude "spec/**/*"
    gem.files.exclude "Rakefile"
    gem.files.exclude "VERSION"
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

require 'spec/rake/spectask'
%w[postgresql mysql mysql2 sqlite3].each do |adapter|
  namespace adapter do
    Spec::Rake::SpecTask.new(:spec) do |spec|
      spec.libs << 'lib' << 'spec' << "spec/connections/#{adapter}"
      spec.spec_files = FileList['spec/**/*_spec.rb']
    end
  end
end

desc 'Run postgresql mysql, mysql2 and sqlite3 specs'
task :spec do 
  %w[postgresql mysql mysql2 sqlite3].each do |adapter|
    Rake::Task["#{adapter}:spec"].invoke
  end
end

task :spec => :check_dependencies

task :default => :spec

namespace :postgresql do
  desc 'Build the PostgreSQL test databases'
  task :build_databases do
    %x( createdb -E UTF8 redhillonrails_core_test )
    %x( createdb -E UTF8 redhillonrails_core_test2 )
  end

  desc 'Drop the PostgreSQL test databases'
  task :drop_databases do
    %x( dropdb redhillonrails_core_unittest )
    %x( dropdb redhillonrails_core_unittest2 )
  end

  desc 'Rebuild the PostgreSQL test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]
end

task :build_postgresql_databases => 'postgresql:build_databases'
task :drop_postgresql_databases => 'postgresql:drop_databases'
task :rebuild_postgresql_databases => 'postgresql:rebuild_databases'

MYSQL_DB_USER = 'redhillonrails_core'
namespace :mysql do
  desc 'Build the MySQL test databases'
  task :build_databases do
    %x( echo "create DATABASE redhillonrails_core_test DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci " | mysql --user=#{MYSQL_DB_USER})
  end

  desc 'Drop the MySQL test databases' 
  task :drop_databases do
    %x( mysqladmin --user=#{MYSQL_DB_USER} -f drop redhillonrails_core_test )
  end

  desc 'Rebuild the MySQL test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]
end

task :build_mysql_databases => 'mysql:build_databases'
task :drop_mysql_databases => 'mysql:drop_databases'
task :rebuild_mysql_databases => 'mysql:rebuild_databases'
