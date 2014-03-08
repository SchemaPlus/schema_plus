print "Using MySQL\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new(File.open("mysql.log", "w"))

ActiveRecord::Base.configurations = {
  'schema_plus' => {
    :adapter => 'mysql',
    :database => 'schema_plus_test',
    :username => ENV.fetch('MYSQL_DB_USER', 'schema_plus'),
    :encoding => 'utf8',
    :min_messages => 'warning'
  }

}

ActiveRecord::Base.establish_connection :schema_plus
