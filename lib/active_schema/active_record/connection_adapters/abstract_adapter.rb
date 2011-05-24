module ActiveSchema
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter
        def self.included(base)
          base.alias_method_chain :initialize, :active_schema
          base.alias_method_chain :drop_table, :active_schema
        end

        def initialize_with_active_schema(*args)
          initialize_without_active_schema(*args)
          adapter = nil
          case adapter_name
            # name of MySQL adapter depends on mysql gem
            # * with mysql gem adapter is named MySQL
            # * with mysql2 gem adapter is named Mysql2
            # Here we handle this and hopefully futher adapter names
          when /^MySQL/i 
            adapter = 'MysqlAdapter'
          when 'PostgreSQL' 
            adapter = 'PostgresqlAdapter'
          when 'SQLite' 
            adapter = 'Sqlite3Adapter'
          end
          if adapter 
            adapter_module = ActiveSchema::ActiveRecord::ConnectionAdapters.const_get(adapter)
            self.class.send(:include, adapter_module) unless self.class.include?(adapter_module)
            self.post_initialize if self.respond_to? :post_initialize
          end
        end

        def create_view(view_name, definition)
          execute "CREATE VIEW #{quote_table_name(view_name)} AS #{definition}"
        end

        def drop_view(view_name)
          execute "DROP VIEW #{quote_table_name(view_name)}"
        end

        def views(name = nil)
          []
        end

        def view_definition(view_name, name = nil)
        end

        def foreign_keys(table_name, name = nil)
          []
        end

        def reverse_foreign_keys(table_name, name = nil)
          []
        end

        def add_foreign_key(table_name, column_names, references_table_name, references_column_names, options = {})
          foreign_key = ForeignKeyDefinition.new(options[:name], table_name, column_names, ::ActiveRecord::Migrator.proper_table_name(references_table_name), references_column_names, options[:on_update], options[:on_delete], options[:deferrable])
          execute "ALTER TABLE #{quote_table_name(table_name)} ADD #{foreign_key}"
        end

        def remove_foreign_key(table_name, foreign_key_name, options = {})
          execute "ALTER TABLE #{quote_table_name(table_name)} DROP CONSTRAINT #{foreign_key_name}"
        end

        def drop_table_with_active_schema(name, options = {})
          unless ::ActiveRecord::Base.connection.class.include?(ActiveSchema::ActiveRecord::ConnectionAdapters::Sqlite3Adapter)
            reverse_foreign_keys(name).each { |foreign_key| remove_foreign_key(foreign_key.table_name, foreign_key.name, options) }
          end
          drop_table_without_active_schema(name, options)
        end

        def supports_partial_indexes?
          false
        end

      end
    end
  end
end
