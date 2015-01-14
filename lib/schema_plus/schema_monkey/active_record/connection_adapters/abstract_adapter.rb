module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter
        def self.included(base) #:nodoc:
          base.alias_method_chain :initialize, :schema_monkey
        end

        def initialize_with_schema_monkey(*args) #:nodoc:
          initialize_without_schema_monkey(*args)

          adapter = case adapter_name
                    when /^MySQL/i                 then 'MysqlAdapter'
                    when 'PostgreSQL', 'PostGIS'   then 'PostgresqlAdapter'
                    when 'SQLite'                  then 'Sqlite3Adapter'
                    end

          SchemaMonkey.include_adapters(self.class, adapter)
        end
      end
    end
  end
end
