require 'simplecov'
require 'simplecov-gem-profile'
SimpleCov.use_merging true
SimpleCov.merge_timeout 3600
SimpleCov.start "gem"

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'active_record'
require 'schema_plus'
require 'schema_dev/rspec'
require 'its-it'

SchemaDev::Rspec.setup

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include(SchemaPlus::Matchers)
  config.include(SchemaPlus::Helpers)
  config.warnings = true
end

def with_fk_config(opts, &block)
  save = Hash[opts.keys.collect{|key| [key, SchemaPlus::ForeignKeys.config.send(key)]}]
  begin
    SchemaPlus::ForeignKeys.config.update_attributes(opts)
    yield
  ensure
    SchemaPlus::ForeignKeys.config.update_attributes(save)
  end
end

def with_fk_auto_create(value = true, &block)
  with_fk_config(:auto_create => value, &block)
end

def define_schema(config={}, &block)
  with_fk_config(config) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        connection.tables.each do |table|
          drop_table table, force: :cascade
        end
        instance_eval &block
      end
    end
  end
end

def remove_all_models
    ObjectSpace.each_object(Class) do |c|
      next unless c.ancestors.include? ActiveRecord::Base
      next if c == ActiveRecord::Base
      next if c.name.blank?
      ActiveSupport::Dependencies.remove_constant c.name
    end
  end

SimpleCov.command_name "[ruby #{RUBY_VERSION} - ActiveRecord #{::ActiveRecord::VERSION::STRING} - #{ActiveRecord::Base.connection.adapter_name}]"

