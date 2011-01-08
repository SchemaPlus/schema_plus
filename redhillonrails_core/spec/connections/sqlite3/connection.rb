print "Using SQLite3\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

ActiveRecord::Base.configurations = {
  'redhillonrails' => {
    :adapter => 'sqlite3',
    :database => File.expand_path(File.dirname(__FILE__) + 'redhillonrails_core.db')
  }

}

ActiveRecord::Base.establish_connection 'redhillonrails'
