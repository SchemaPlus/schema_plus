module SchemaDbDefault
  module Middleware
    module PostgresqlAdapter
      def self.insert
        SchemaMonkey::Middleware::Query::ExecCache.insert(0, BindDbDefault)
      end
    end

    # Middleware to replace each ActiveRecord::DB_DEFAULT with a literal
    # DEFAULT in the sql string, for postgresql.  The underlying pg gem provides no
    # way to bind a value that will replace $n with DEFAULT.
    class BindDbDefault < SchemaMonkey::Middleware::Base
      def call(env)
        if env.binds.any?{ |col, val| val.equal? ::ActiveRecord::DB_DEFAULT}
          j = 0
          env.binds.each_with_index do |(col, val), i|
            if val.equal? ::ActiveRecord::DB_DEFAULT
              env.sql = env.sql.sub(/\$#{i+1}/, 'DEFAULT')
            else
              env.sql = env.sql.sub(/\$#{i+1}/, "$#{j+1}") if i != j
              j += 1
            end
          end
          env.binds = env.binds.reject{|col, val| val.equal? ::ActiveRecord::DB_DEFAULT}
        end
        @app.call(env)
      end
    end
  end
end
