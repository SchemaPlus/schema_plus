require 'schema_monkey'

require_relative 'schema_default_expr/middleware'

module SchemaDefaultExpr
  module ActiveRecord
    module ConnectionAdapters
      #
      # Each adapter needs to define these two functions:
      #
      # default_expr_valid?(expr)
      #
      # Return true if the passed expression can be used as a column
      # default value.  (For most databases the specific expression
      # doesn't matter, and the adapter's function would return a
      # constant true if default expressions are supported or false if
      # they're not.)
      #
      # sql_for_function(function_name)
      #
      # Return SQL definition for a given canonical function_name symbol.
      # Currently, the only function to support is :now, which should
      # return a DATETIME object for the current time.
      #
      autoload :MysqlAdapter, 'schema_default_expr/active_record/connection_adapters/mysql_adapter'
      autoload :PostgresqlAdapter, 'schema_default_expr/active_record/connection_adapters/postgresql_adapter'
      autoload :Sqlite3Adapter, 'schema_default_expr/active_record/connection_adapters/sqlite3_adapter'
    end
  end
end

SchemaMonkey.register(SchemaDefaultExpr)
