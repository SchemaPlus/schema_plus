module AutomaticForeignKeyHelpers
  extend self

  def mysql?
    ActiveRecord::Base.connection.adapter_name =~ /^mysql/i
  end

end
