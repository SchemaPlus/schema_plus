print "Using MySQL2\n"
require 'logger'

ActiveRecord::Base.configurations = {
  'afk' => {
    :adapter => 'mysql2',
    :database => 'afk_unittest',
    :username => 'afk',
    :encoding => 'utf8',
    :socket => '/var/run/mysqld/mysqld.sock',
    :min_messages => 'warning'
  }

}

ActiveRecord::Base.establish_connection 'afk'
