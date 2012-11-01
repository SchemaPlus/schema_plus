if RUBY_VERSION > "1.9"
  require 'simplecov'
  require 'simplecov-gem-adapter'
  SimpleCov.start "gem"
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'active_record'
require 'schema_plus'
require 'connection'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include(SchemaPlusMatchers)
  config.include(SchemaPlusHelpers)
end

def with_fk_auto_create(value = true)
  old_value = SchemaPlus.config.foreign_keys.auto_create
  SchemaPlus.config.foreign_keys.auto_create = value
  begin
    yield
  ensure
    SchemaPlus.config.foreign_keys.auto_create = old_value
  end
end


def create_schema(&block)
   ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        connection.tables.each do |table|
          drop_table table
        end
        instance_eval &block
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
