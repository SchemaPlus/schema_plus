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
          Middleware::Migration::Column.use Column
        end

        class Column < SchemaMonkey::Middleware::Base
          def call(env)
            case env.type.to_sym
            when :references then env.table_definition.send :references_without_schema_monkey, env.name, env.options
            when :belongs_to then env.table_definition.send :references_without_schema_monkey, env.name, env.options
            else env.table_definition.send :column_without_schema_monkey, env.name, env.type, env.options
            end
          end
        end

        def column_with_schema_monkey(name, type, options = {})
          Middleware::Migration::Column.call Middleware::Migration::Column::Env.new(table_definition: self, name: name, type: type, options: options.dup)
        end

        def references_with_schema_monkey(name, options = {})
          Middleware::Migration::Column.call Middleware::Migration::Column::Env.new(table_definition: self, name: name, type: :references, options: options.dup)
        end

        def belongs_to_with_schema_monkey(name, options = {})
          Middleware::Migration::Column.call Middleware::Migration::Column::Env.new(table_definition: self, name: name, type: :belongs_to, options: options.dup)
        end
      end
    end
  end
end
