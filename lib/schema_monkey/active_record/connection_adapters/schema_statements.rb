module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module SchemaStatements
        module Column
          def self.included(base)
            base.class_eval do
              alias_method_chain :add_column, :schema_monkey
              alias_method_chain :change_column, :schema_monkey
            end
          end

          def add_column_with_schema_monkey(table_name, name, type, options = {})
            Middleware::Migration::Column.start caller: self, operation: :add, table_name: table_name, name: name, type: type, options: options.dup do |env|
              add_column_without_schema_monkey env.table_name, env.name, env.type, env.options
            end
          end

          def change_column_with_schema_monkey(table_name, name, type, options = {})
            Middleware::Migration::Column.start caller: self, operation: :change, table_name: table_name, name: name, type: type, options: options.dup do |env|
              change_column_without_schema_monkey env.table_name, env.name, env.type, env.options
            end
          end
        end
        module Reference
          def self.included(base)
            base.class_eval do
              alias_method_chain :add_reference, :schema_monkey
            end
          end
          def add_reference_with_schema_monkey(table_name, name, options = {})
            Middleware::Migration::Column.start caller: self, operation: :add, table_name: table_name, name: name, type: :reference, options: options.dup do |env|
              add_reference_without_schema_monkey env.table_name, env.name, env.options
            end
          end
        end
        module Index
          def self.included(base)
            base.class_eval do
              alias_method_chain :add_index, :schema_monkey
            end
          end
          def add_index_with_schema_monkey(table_name, column_names, options={})
            if column_names.is_a? Hash and options.empty?
                options = column_names
                column_names = nil
            end
            Middleware::Migration::Index.start caller: self, operation: :add, table_name: table_name, column_names: column_names, options: options.dup do |env|
              add_index_without_schema_monkey env.table_name, env.column_names, env.options
            end
          end
        end
      end
    end
  end
end
