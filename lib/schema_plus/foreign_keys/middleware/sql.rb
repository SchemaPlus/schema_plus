module SchemaPlus::ForeignKeys
  module Middleware
    module Sql
      module Table
        def after(env)
          foreign_keys = case ::ActiveRecord.version
                         when Gem::Version.new("4.2.0") then env.table_definition.foreign_keys
                         else env.table_definition.foreign_keys.values
                         end

          # create foreign key constraints inline in table definition
          env.sql.body = ([env.sql.body] + foreign_keys.map(&:to_sql)).join(', ')
 
          # prevents AR >= 4.2.1 from emitting add_foreign_key after the table
          env.table_definition.foreign_keys.clear
        end
      end
    end
  end
end
