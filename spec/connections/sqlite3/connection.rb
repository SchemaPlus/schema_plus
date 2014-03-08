print "Using SQLite3\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new(File.open("sqlite3.log", "w"))

ActiveRecord::Base.configurations = {
  'schema_plus' => {
    :adapter => 'sqlite3',
    :database => File.expand_path('schema_plus.sqlite3', File.dirname(__FILE__)),
  }

}

ActiveRecord::Base.establish_connection :schema_plus
ActiveRecord::Base.connection.execute "PRAGMA synchronous = OFF"
