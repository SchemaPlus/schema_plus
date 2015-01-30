module SchemaPlusDefaultExpr
  module ActiveRecord
    module ConnectionAdapters

      module Sqlite3Adapter
        def self.included(base)
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::Column, SQLiteColumn
        end

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

      module SQLiteColumn

        def self.included(base)
          base.alias_method_chain :default_function, :sqlite3 if base.instance_methods.include? :default_function
        end

        def default_function_with_sqlite3
          @default_function ||= "(#{default})" if default =~ /DATETIME/
          default_function_without_sqlite3
        end
      end
    end
  end
end
