$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'redhillonrails_core'
require 'connection'
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

Spec::Runner.configure do |config|
  config.include(RedhillonrailsCoreMatchers)
end

def load_schema
  eval(File.read(File.join(File.dirname(__FILE__), 'schema', 'schema.rb')))
end
