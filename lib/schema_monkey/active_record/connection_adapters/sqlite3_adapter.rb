module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module Sqlite3Adapter

        def self.included(base)
          base.class_eval do
            alias_method_chain :indexes, :schema_monkey
            alias_method_chain :tables, :schema_monkey
          end
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::SchemaStatements, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Column
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::SchemaStatements, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Reference
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::SchemaStatements, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Index
        end

        def indexes_with_schema_monkey(table_name, query_name=nil)
          Middleware::Query::Indexes.start connection: self, table_name: table_name, query_name: query_name do |env|
            env.index_definitions += indexes_without_schema_monkey env.table_name, env.query_name
          end
        end

        def tables_with_schema_monkey(query_name=nil, table_name=nil)
          Middleware::Query::Tables.start connection: self, query_name: query_name, table_name: table_name do |env|
            env.tables += tables_without_schema_monkey env.query_name, env.table_name
          end
        end

      end
    end
  end
end


