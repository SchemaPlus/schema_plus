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

def load_schema(name)
  ActiveRecord::Migration.suppress_messages do
    eval(File.read(File.join(File.dirname(__FILE__), 'schema', name)))
  end
end

def load_core_schema
  SchemaPlus.setup do |config|
    config.foreign_keys.auto_create = false;
  end
  load_schema('core_schema.rb')
  load 'models/user.rb'
  load 'models/post.rb'
  load 'models/comment.rb'
end

def load_auto_schema
  SchemaPlus.setup do |config|
    config.foreign_keys.auto_create = true;
  end
  load_schema('auto_schema.rb')
  load 'models/user.rb'
  load 'models/post.rb'
  load 'models/comment.rb'
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
