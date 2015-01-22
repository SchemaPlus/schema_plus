require 'schema_monkey'

require_relative 'schema_plus_tables/active_record/connection_adapters/abstract_adapter'
#require_relative 'schema_plus_tables/middleware'

module SchemaPlusTables
  module ActiveRecord
    module ConnectionAdapters
      autoload :MysqlAdapter, 'schema_plus_tables/active_record/connection_adapters/mysql_adapter'
      autoload :PostgresqlAdapter, 'schema_plus_tables/active_record/connection_adapters/postgresql_adapter'
      autoload :Sqlite3Adapter, 'schema_plus_tables/active_record/connection_adapters/sqlite3_adapter'
    end
  end
end

SchemaMonkey.register(SchemaPlusTables)
