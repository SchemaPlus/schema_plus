module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module SchemaStatements
        def self.included(base)
          base.class_eval do
            alias_method_chain :add_column, :schema_monkey
            alias_method_chain :change_column, :schema_monkey
          end
        end

        def add_column_with_schema_monkey(table_name, column_name, type, options = {})
          Middleware::Migration::Column.start caller: self, operation: :add, table_name: table_name, name: column_name, type: type, options: options.dup do |app, env|
            add_column_without_schema_monkey env.table_name, env.name, env.type, env.options
          end
        end

        def change_column_with_schema_monkey(table_name, column_name, type, options = {})
          Middleware::Migration::Column.start caller: self, operation: :change, table_name: table_name, name: column_name, type: type, options: options.dup do |app, env|
            change_column_without_schema_monkey env.table_name, env.name, env.type, env.options
          end
        end
      end
    end
  end
end
