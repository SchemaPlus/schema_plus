module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module MysqlAdapter

        def self.included(base)
          base.class_eval do
            alias_method_chain :indexes, :schema_monkey
          end
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Column
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Reference
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Index
        end

        def indexes_with_schema_monkey(table_name, query_name=nil)
          Middleware::Query::Indexes.start connection: self, table_name: table_name, query_name: query_name do |env|
            env.index_definitions += indexes_without_schema_monkey env.table_name, env.query_name
          end
        end
      end
    end
  end
end

