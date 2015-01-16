module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter

        def self.included(base)
          base.class_eval do
            alias_method_chain :exec_cache, :schema_monkey
          end
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::SchemaStatements, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Reference
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Column
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Index
        end

        def exec_cache_with_schema_monkey(sql, name, binds)
          Middleware::Query::ExecCache.start adapter: self, sql: sql, name: name, binds: binds do |env|
            exec_cache_without_schema_monkey(env.sql, env.name, env.binds)
          end
        end
      end
    end
  end
end
