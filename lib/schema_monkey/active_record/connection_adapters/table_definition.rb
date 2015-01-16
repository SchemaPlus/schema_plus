module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module TableDefinition
        def self.included(base)
          base.class_eval do
            alias_method_chain :column, :schema_monkey
            alias_method_chain :references, :schema_monkey
            alias_method_chain :belongs_to, :schema_monkey
          end
        end

        def column_with_schema_monkey(name, type, options = {})
          Middleware::Migration::Column.start caller: self, operation: :define, table_name: self.name, name: name, type: type, options: options.dup do |app, env|
            column_without_schema_monkey env.name, env.type, env.options
          end
        end

        def references_with_schema_monkey(name, options = {})
          Middleware::Migration::Column.start caller: self, operation: :define, table_name: self.name, name: name, type: :references, options: options.dup do |app, env|
            references_without_schema_monkey env.name, env.options
          end
        end

        def belongs_to_with_schema_monkey(name, options = {})
          Middleware::Migration::Column.start caller: self, operation: :define, table_name: self.name, name: name, type: :belongs_to, options: options.dup do |app, env|
            belongs_to_without_schema_monkey env.name, env.options
          end
        end
      end
    end
  end
end
