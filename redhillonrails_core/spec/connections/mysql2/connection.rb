print "Using MySQL2\n"
require 'logger'

ActiveRecord::Base.configurations = {
  'redhillonrails' => {
    :adapter => 'mysql2',
    :database => 'redhillonrails_core_test',
    :username => 'redhillonrails',
    :encoding => 'utf8',
    :socket => '/var/run/mysqld/mysqld.sock',
    :min_messages => 'warning'
  }

}

ActiveRecord::Base.establish_connection 'redhillonrails'
