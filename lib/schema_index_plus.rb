require 'schema_monkey'

require_relative 'schema_index_plus/middleware'
require_relative 'schema_index_plus/active_record/connection_adapters/abstract_adapter'

module SchemaIndexPlus
  module ActiveRecord
    module ConnectionAdapters
      autoload :PostgresqlAdapter, 'schema_index_plus/active_record/connection_adapters/postgresql_adapter'
      autoload :MysqlAdapter, 'schema_index_plus/active_record/connection_adapters/mysql_adapter'
      autoload :Sqlite3Adapter, 'schema_index_plus/active_record/connection_adapters/sqlite3_adapter'
    end
  end
end

SchemaMonkey.register(SchemaIndexPlus)
