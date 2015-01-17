require 'schema_monkey'

require_relative 'schema_index_plus/middleware'
require_relative 'schema_index_plus/active_record/connection_adapters/abstract_adapter'
require_relative 'schema_index_plus/active_record/connection_adapters/column'
require_relative 'schema_index_plus/active_record/base'

module SchemaIndexPlus
  module ActiveRecord
    module ConnectionAdapters
      autoload :PostgresqlAdapter, 'schema_index_plus/active_record/connection_adapters/postgresql_adapter'
      autoload :MysqlAdapter, 'schema_index_plus/active_record/connection_adapters/mysql_adapter'
      autoload :Sqlite3Adapter, 'schema_index_plus/active_record/connection_adapters/sqlite3_adapter'
    end
  end

  def self.insert
    SchemaMonkey.patch ::ActiveRecord::Base, self
    SchemaMonkey.patch ::ActiveRecord::ConnectionAdapters::Column, self
  end

end

SchemaMonkey.register(SchemaIndexPlus)
