$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rspec'
require 'automatic_foreign_key'
require 'connection'
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include(AutomaticForeignKeyMatchers)
end

def load_schema
  eval(File.read(File.join(File.dirname(__FILE__), 'schema', 'schema.rb')))
end
