print "Using SQLite3\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new(File.open("sqlite3.log", "w"))

ActiveRecord::Base.configurations = {
  'active_schema' => {
    :adapter => 'sqlite3',
    :database => File.expand_path('active_schema.sqlite3', File.dirname(__FILE__)),
  }

}

ActiveRecord::Base.establish_connection 'active_schema'
