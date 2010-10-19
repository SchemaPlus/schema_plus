require "redhillonrails_core"

class User < ActiveRecord::Base
end

# We drop and reload the schema on all specs, to make it easier to know what'll be in the DB

case ENV["ADAPTER"]
when "postgresql"
  ActiveRecord::Base.establish_connection :adapter => "postgresql", :database => "redhillonrails_core_test"
else
  raise ArgumentError, "ADAPTER environment variable left unset: run tests and set ADAPTER to a known value. Valid values are: postgresql"
end
