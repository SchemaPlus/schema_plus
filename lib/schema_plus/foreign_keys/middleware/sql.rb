module SchemaPlusForeignKeys
  module Middleware
    module Sql
      module Table
        def after(env)
          env.sql.body = ([env.sql.body] + env.table_definition.foreign_keys.map(&:to_sql)).join(', ')
        end
      end
    end
  end
end
