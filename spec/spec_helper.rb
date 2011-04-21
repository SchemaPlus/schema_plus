$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rspec'
require 'active_record'
require 'active_schema'
require 'connection'

ActiveSchema.insert

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include(ActiveSchemaMatchers)
  config.include(ActiveSchemaHelpers)
end

def load_schema(name)
  ActiveRecord::Migration.suppress_messages do
    eval(File.read(File.join(File.dirname(__FILE__), 'schema', name)))
  end
end

def load_core_schema
  ActiveSchema.config.foreign_keys.auto_create = false;
  load_schema('core_schema.rb')
end

def load_auto_schema
  ActiveSchema.config.foreign_keys.auto_create = true;
  load_schema('auto_schema.rb')
end


