if RUBY_VERSION > "1.9"
  require 'simplecov'
  require 'simplecov-gem-adapter'
  SimpleCov.start "gem"
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'active_record'

if defined? JRUBY_VERSION
  require 'arjdbc'
end

require 'schema_plus'
require 'connection'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include(SchemaPlusMatchers)
  config.include(SchemaPlusHelpers)
end

def with_fk_config(opts, &block)
  save = Hash[opts.keys.collect{|key| [key, SchemaPlus.config.foreign_keys.send(key)]}]
  begin
    SchemaPlus.config.foreign_keys.update_attributes(opts)
    yield
  ensure
    SchemaPlus.config.foreign_keys.update_attributes(save)
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
          drop_table table
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

SimpleCov.command_name ActiveRecord::Base.connection.adapter_name if defined? SimpleCov
