print "Using MySQL\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

ActiveRecord::Base.configurations = {
  'afk' => {
    :adapter => 'mysql',
    :database => 'afk_unittest',
    :username => 'afk',
    :encoding => 'utf8',
    :socket => '/var/run/mysqld/mysqld.sock',
    :min_messages => 'warning'
  }

}

ActiveRecord::Base.establish_connection 'afk'
