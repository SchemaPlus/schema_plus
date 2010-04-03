require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

ActiveRecord::Base.configurations = {
  'afk' => {
    :adapter => 'postgresql',
    :database => 'afk_unittest',
    :min_messages => 'warning'
  }

}

ActiveRecord::Base.establish_connection 'afk'
