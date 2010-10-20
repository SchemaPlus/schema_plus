require "micronaut"
require "active_record"
require "redhillonrails_core"
require "fileutils"

begin
  require "ruby-debug"
rescue LoadError
  # Don't care - debugging won't be available
end

# Log data somewhere interesting
FileUtils.mkdir_p("log") rescue nil
ActiveRecord::Base.logger = Logger.new("log/test.log")

# The model we'll be playing along with. Nothing ActiveRecord-like is expected or required here.
class User < ActiveRecord::Base
end

# We drop and reload the schema on all specs, to make it easier to know what'll be in the DB
case ENV["ADAPTER"]
when "postgresql"
  ActiveRecord::Base.establish_connection :adapter => "postgresql", :database => "redhillonrails_core_test", :min_messages => "warning"
else
  raise ArgumentError, "ADAPTER environment variable left unset: run tests and set ADAPTER to a known value. Valid values are: postgresql"
end

Micronaut.configure do |c|
  c.before :each do
    @migrator.suppress_messages do
      @migrator.up
    end
  end

  c.before :each do
    User.reset_column_information
  end

  c.after :each do
    @migrator.suppress_messages do
      @migrator.down
    end
  end
end
