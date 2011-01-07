print "Using SQLite3\n"
require 'logger'

ActiveRecord::Base.configurations = {
  'redhillonrails' => {
    :adapter => 'sqlite3',
    :database => File.expand_path(File.dirname(__FILE__) + 'redhillonrails_core.db')
  }

}

ActiveRecord::Base.establish_connection 'redhillonrails'
