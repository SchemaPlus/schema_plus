$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'active_record'
require 'redhillonrails_core'
require 'connection'
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

Spec::Runner.configure do |config|
  config.include(RedhillonrailsCoreMatchers)
  # load schema
  ActiveRecord::Migration.suppress_messages do
    eval(File.read(File.join(File.dirname(__FILE__), 'schema', 'schema.rb')))
  end
end

