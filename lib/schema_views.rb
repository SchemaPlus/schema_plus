require 'schema_monkey'

require_relative 'schema_views/active_record/connection_adapters/abstract_adapter'
require_relative 'schema_views/middleware'

module SchemaViews
  module ActiveRecord
    module ConnectionAdapters
      autoload :Mysql2Adapter, 'schema_views/active_record/connection_adapters/mysql2_adapter'
      autoload :PostgresqlAdapter, 'schema_views/active_record/connection_adapters/postgresql_adapter'
      autoload :Sqlite3Adapter, 'schema_views/active_record/connection_adapters/sqlite3_adapter'
    end
  end
end

SchemaMonkey.register(SchemaViews)
