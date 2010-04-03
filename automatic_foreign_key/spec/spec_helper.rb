$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'automatic_foreign_key'
require 'spec'
require 'spec/autorun'
require 'connection'

Spec::Runner.configure do |config|
end

def load_schema
  eval(File.read(File.join(File.dirname(__FILE__), 'schema', 'schema.rb')))
end
