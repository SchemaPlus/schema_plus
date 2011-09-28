module SchemaPlusHelpers
  extend self

  def mysql?
    ActiveRecord::Base.connection.adapter_name =~ /^mysql/i
  end

  def postgresql?
    ActiveRecord::Base.connection.adapter_name =~ /^postgresql/i
  end

  def sqlite3?
    ActiveRecord::Base.connection.adapter_name =~ /^sqlite/i
  end

  def suppress_messages
    ActiveRecord::Migration.suppress_messages { yield }
  end

end
