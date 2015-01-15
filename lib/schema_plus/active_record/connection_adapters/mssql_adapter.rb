module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters
      # SchemaPlus includes a MySQL implementation of the AbstractAdapter
      # extensions.  (This works with both the <tt>mysql</t> and
      # <tt>mysql2</tt> gems.)
      module MssqlAdapter
        module AddColumnOptions
          def default_expr_valid?(expr)
            false # only the TIMESTAMP column accepts SQL column defaults and rails uses DATETIME
          end
          def sql_for_function(function)
            case function
            when :now then 'GETDATE()'
            end
          end
        end
      end
    end
  end
end
