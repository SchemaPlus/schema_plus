module SchemaPlus::DefaultExpr
  module ActiveRecord
    module ConnectionAdapters
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
