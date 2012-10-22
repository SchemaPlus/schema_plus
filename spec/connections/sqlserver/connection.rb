print "Using SQL Server\n"
require 'logger'

ActiveRecord::Base.logger = Logger.new(File.open("sqlserver.log", "w"))

def fetch_host
  ENV.fetch('SQLSERVER_DB_HOST', '127.0.0.1')
end

ActiveRecord::Base.configurations = {
  'schema_plus' => {
    :adapter => 'sqlserver',
    :mode => 'dblib',
    :username => ENV.fetch('SQLSERVER_DB_USER', 'schema_plus'),
    :password => ENV["SQLSERVER_DB_PASSWD"],
    :database => 'schema_plus_unittest',
    :min_messages => 'warning',
    :host => fetch_host
  }

}

ActiveRecord::Base.establish_connection 'schema_plus'