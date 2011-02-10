print "Using PostgreSQL\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

ActiveRecord::Base.configurations = {
  'redhillonrails' => {
    :adapter => 'postgresql',
    :database => 'redhillonrails_core_test',
    :min_messages => 'warning'
  }

}

ActiveRecord::Base.establish_connection 'redhillonrails'
