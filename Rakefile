require 'bundler'
Bundler::GemHelper.install_tasks

DATABASES = %w[schema_plus_test]
ADAPTERS = {
  postgresql: {uservar: 'POSTGRES_DB_USER', defaultuser: 'postgres', create: "createdb -U '%{user}' %{dbname}", drop: "dropdb -U '%{user}' %{dbname}" },
  mysql: {uservar: 'MYSQL_DB_USER', defaultuser: 'schema_plus', create: "mysqladmin -u '%{user}' create %{dbname}", drop: "mysqladmin -u '%{user}' -f drop %{dbname}" },
  mysql2: nil,
  sqlite3: nil,
}

task :default => :spec

desc 'Run test for adapter whose name is suffix of current Gemfile'
task :spec do
    gemfile = ENV['BUNDLE_GEMFILE']
    fail "BUNDLE_GEMFILE environment variable not set" unless gemfile
    adapter = File.extname(gemfile).sub(/^[.]/, '')
    fail "BUNDLE_GEMFILE filename does not end with .db adapter name" if adapter.empty?
    Rake::Task["#{adapter}:spec"].invoke
end

# work around a bug in rake 10.0.3 with ruby 1.9.2
unless RUBY_VERSION == "1.9.2"
    require 'rdoc/task'
    Rake::RDocTask.new do |rdoc|
    require File.dirname(__FILE__) + '/lib/schema_plus/version'

    rdoc.rdoc_dir = 'rdoc'
    rdoc.title = "schema_plus #{SchemaPlus::VERSION}"
    rdoc.rdoc_files.include('README*')
    rdoc.rdoc_files.include('lib/**/*.rb')
    end
end

require 'rspec/core/rake_task'
ADAPTERS.keys.each do |adapter|
  namespace adapter do
    RSpec::Core::RakeTask.new(:spec) do |spec|
      ENV[ADAPTERS[adapter][:uservar]] ||= ADAPTERS[adapter][:defaultuser] if ADAPTERS[adapter]
      spec.rspec_opts = "-Ispec/connections/#{adapter}"
      spec.fail_on_error = true
    end
  end
end

ADAPTERS.each do |name, db|
  next unless db
  namespace name do
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

desc "Run #{ADAPTERS.keys.tap{|l| l[-1] = "and #{l[-1]}"}.join(', ')} tests"
task :specs do 
  invoke_multiple(ADAPTERS.keys, "spec")
end

desc 'Create test databases'
task :create_databases do
  invoke_multiple(ADAPTERS.select{|k,v| v}.keys, "create_databases")
end

desc 'Drop test databases'
task :drop_databases do
  invoke_multiple(ADAPTERS.select{|k,v| v}.keys, "drop_databases")
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
