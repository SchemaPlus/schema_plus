require 'bundler'
Bundler::GemHelper.install_tasks

require 'schema_dev/tasks'

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
require File.dirname(__FILE__) + '/lib/schema_plus/version'

rdoc.rdoc_dir = 'rdoc'
rdoc.title = "schema_plus #{SchemaPlus::VERSION}"
rdoc.rdoc_files.include('README*')
rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
