print "Using PostgreSQL\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new(File.open("postgresql.log", "w"))

ActiveRecord::Base.configurations = {
  'schema_plus' => {
    :adapter => 'postgresql',
    :username => ENV['POSTGRES_DB_USER'],
    :database => 'schema_plus_test',
    :min_messages => 'warning'
  }

}

ActiveRecord::Base.establish_connection :schema_plus
