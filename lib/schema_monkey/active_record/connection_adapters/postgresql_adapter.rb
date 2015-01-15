module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter
        def self.included(base)
          base.class_eval do
            alias_method_chain :exec_cache, :schema_monkey
            Middleware::Query::ExecCache.use ExecCache
          end
        end

        class ExecCache < Middleware::Base
          def call(env)
            env.adapter.send :exec_cache_without_schema_monkey, env.sql, env.name, env.binds
          end
        end

        def exec_cache_with_schema_monkey(sql, name, binds)
          Middleware::Query::ExecCache.call Middleware::Query::ExecCache::Env.new(adapter: self, sql: sql, name: name, binds: binds)
        end
      end
    end
  end
end
