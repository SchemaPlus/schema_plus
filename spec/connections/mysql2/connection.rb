print "Using MySQL2\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new(File.open("mysql2.log", "w"))

ActiveRecord::Base.configurations = {
  'schema_plus' => {
    :adapter => 'mysql2',
    :database => 'schema_plus_unittest',
    :username => 'schema_plus',
    :encoding => 'utf8',
    :socket => '/tmp/mysql.sock',
    :min_messages => 'warning'
  }

}

ActiveRecord::Base.establish_connection 'schema_plus'
