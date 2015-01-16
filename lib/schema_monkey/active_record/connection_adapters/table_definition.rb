module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module TableDefinition
        def self.included(base)
          base.class_eval do
            alias_method_chain :column, :schema_monkey
            alias_method_chain :references, :schema_monkey
            alias_method_chain :belongs_to, :schema_monkey
            alias_method_chain :index, :schema_monkey
          end
        end

        def column_with_schema_monkey(name, type, options = {})
          Middleware::Migration::Column.start caller: self, operation: :define, table_name: self.name, name: name, type: type, options: options.dup do |env|
            column_without_schema_monkey env.name, env.type, env.options
          end
        end

        def references_with_schema_monkey(name, options = {})
          Middleware::Migration::Column.start caller: self, operation: :define, table_name: self.name, name: name, type: :reference, options: options.dup do |env|
            references_without_schema_monkey env.name, env.options
          end
        end

        def belongs_to_with_schema_monkey(name, options = {})
          Middleware::Migration::Column.start caller: self, operation: :define, table_name: self.name, name: name, type: :reference, options: options.dup do |env|
            belongs_to_without_schema_monkey env.name, env.options
          end
        end

        def index_with_schema_monkey(column_name, options = {})
          Middleware::Migration::Index.start caller: self, operation: :define, table_name: self.name, column_names: column_name, options: options.dup do |env|
            index_without_schema_monkey env.column_names, env.options
          end
        end
      end
    end
  end
end
