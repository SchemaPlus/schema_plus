print "Using PostgreSQL\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new(File.open("postgresql.log", "w"))

ActiveRecord::Base.configurations = {
  'active_schema' => {
    :adapter => 'postgresql',
    :database => 'active_schema_unittest',
    :min_messages => 'warning'
  }

}

ActiveRecord::Base.establish_connection 'active_schema'
