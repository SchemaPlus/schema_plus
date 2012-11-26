require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
%w[postgresql mysql mysql2 sqlite3].each do |adapter|
  namespace adapter do
    RSpec::Core::RakeTask.new(:spec) do |spec|
      spec.rspec_opts = "-Ispec/connections/#{adapter}"
      spec.fail_on_error = true
    end
  end
end


task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  require File.dirname(__FILE__) + '/lib/schema_plus/version'

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "schema_plus #{SchemaPlus::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

DATABASES = %w[schema_plus_test]
[ 
  { namespace: :postgresql, uservar: 'POSTGRES_DB_USER', defaultuser: 'postgres', create: "createdb -U '%{user}' %{dbname}", drop: "dropdb -U '%{user}' %{dbname}" },
  { namespace: :mysql, uservar: 'MYSQL_DB_USER', defaultuser: 'schema_plus', create: "mysqladmin -u '%{user}' create %{dbname}", drop: "mysqladmin -u '%{user}' -f drop %{dbname}" }
].each do |db|
  namespace db[:namespace] do
    user = ENV.fetch db[:uservar], db[:defaultuser]
    task :create_databases do
      DATABASES.each do |dbname|
        system(db[:create] % {user: user, dbname: dbname})
      end
    end
    task :drop_databases do
      DATABASES.each do |dbname|
        system(db[:drop] % {user: user, dbname: dbname})
      end
    end
  end
end

desc 'Run postgresql, mysql2 and sqlite3 tests'
task :spec do 
  invoke_multiple(%w[postgresql mysql mysql2 sqlite3], "spec")
end

desc 'Create test databases'
task :create_databases do
  invoke_multiple(%w[postgresql mysql], "create_databases")
end

desc 'Drop test databases'
task :drop_databases do
  invoke_multiple(%w[postgresql mysql], "drop_databases")
end

def invoke_multiple(namespaces, task)
  failed = namespaces.reject { |adapter|
    begin
      Rake::Task["#{adapter}:#{task}"].invoke
      true
    rescue => e
      warn "\n#{e}\n"
      false
    end
  }
  fail "Failure in: #{failed.join(', ')}" if failed.any?
end
