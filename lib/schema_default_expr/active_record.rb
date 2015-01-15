module SchemaDefaultExpr
  module ActiveRecord
    module ConnectionAdapters
      #####################################################################
      #
      # Each adapter needs to define these two functions:
      # define them all. Defining them here only for reference.

      # default_expr_valid?(expr) 
      #
      # Return true if the passed expression can be used as a column
      # default value.  (For most databases the specific expression
      # doesn't matter, and the adapter's function would return a
      # constant true if default expressions are supported or false if
      # they're not.)

      # sql_for_function(function_name)
      #
      # Return SQL definition for a given canonical function_name symbol.
      # Currently, the only function to support is :now, which should
      # return a DATETIME object for the current time.

      module PostgresqlAdapter
        def default_expr_valid?(expr)
          true # arbitrary sql is okay in PostgreSQL
        end

        def sql_for_function(function)
          case function
          when :now
            "NOW()"
          end
        end
      end

      module MysqlAdapter
        def default_expr_valid?(expr)
          false # only the TIMESTAMP column accepts SQL column defaults and rails uses DATETIME
        end

        def sql_for_function(function)
          case function
          when :now then 'CURRENT_TIMESTAMP'
          end
        end
      end

      module Sqlite3Adapter
        def default_expr_valid?(expr)
          true # arbitrary sql is okay
        end

        def sql_for_function(function)
          case function
          when :now
            "(DATETIME('now'))"
          end
        end
      end
    end
  end
end
