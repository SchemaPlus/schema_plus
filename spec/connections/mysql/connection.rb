print "Using MySQL\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new(File.open("mysql.log", "w"))

ActiveRecord::Base.configurations = {
  'active_schema' => {
    :adapter => 'mysql',
    :database => 'active_schema_unittest',
    :username => 'active_schema',
    :encoding => 'utf8',
    :socket => '/tmp/mysql.sock',
    :min_messages => 'warning'
  }

}

ActiveRecord::Base.establish_connection 'active_schema'
