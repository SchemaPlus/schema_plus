module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter
        def self.included(base) #:nodoc:
          base.alias_method_chain :initialize, :schema_monkey
        end

        def initialize_with_schema_monkey(*args) #:nodoc:
          adapter = case adapter_name
                    when /^MySQL/i                 then 'MysqlAdapter'
                    when 'PostgreSQL', 'PostGIS'   then 'PostgresqlAdapter'
                    when 'SQLite'                  then 'Sqlite3Adapter'
                    end

          SchemaMonkey.adapters.each do |mod|
            [:AbstractAdapter, adapter].each do |mixin|
              if mod.const_defined?(mixin)
                mod_adapter = mod.const_get(mixin)
                self.class.send(:include, mod_adapter) unless self.class.include?(mod_adapter)
              end
            end
          end

          initialize_without_schema_monkey(*args)
        end
      end
    end
  end
end
