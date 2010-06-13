print "Using PostgreSQL\n"
require 'logger'

ActiveRecord::Base.configurations = {
  'afk' => {
    :adapter => 'postgresql',
    :database => 'afk_unittest',
    :min_messages => 'warning'
  }

}

ActiveRecord::Base.establish_connection 'afk'
