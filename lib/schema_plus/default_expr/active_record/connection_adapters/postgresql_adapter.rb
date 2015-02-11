module SchemaPlus::DefaultExpr
  module ActiveRecord
    module ConnectionAdapters
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
    end
  end
end
