module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter
        def self.included(base) #:nodoc:
          base.alias_method_chain :initialize, :schema_monkey
        end

        def initialize_with_schema_monkey(*args) #:nodoc:
          initialize_without_schema_monkey(*args)

          dbm = case adapter_name
                when /^MySQL/i                 then :Mysql
                when 'PostgreSQL', 'PostGIS'   then :Postgresql
                when 'SQLite'                  then :Sqlite3
                end

          SchemaMonkey.include_adapters(self.class, dbm)
          SchemaMonkey.insert_middleware(dbm)
        end

        module SchemaCreation
          def self.included(base)
            base.class_eval do
              alias_method_chain :add_column_options!, :schema_monkey
            end
          end

          def add_column_options_with_schema_monkey!(sql, options)
            Middleware::Migration::ColumnOptionsSql.start connection: self.instance_variable_get('@conn'), sql: sql, options: options, schema_creation: self do |env|
              add_column_options_without_schema_monkey! env.sql, env.options
            end
          end
        end
      end
    end
  end
end
