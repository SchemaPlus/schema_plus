module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter
        def self.included(base) #:nodoc:
          base.alias_method_chain :initialize, :schema_plus
          base.alias_method_chain :drop_table, :schema_plus
        end

        def initialize_with_schema_plus(*args) #:nodoc:
          initialize_without_schema_plus(*args)
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
            adapter_module = SchemaPlus::ActiveRecord::ConnectionAdapters.const_get(adapter)
            self.class.send(:include, adapter_module) unless self.class.include?(adapter_module)
            self.post_initialize if self.respond_to? :post_initialize
          end
        end

        # Create a view given the SQL definition
        def create_view(view_name, definition)
          execute "CREATE VIEW #{quote_table_name(view_name)} AS #{definition}"
        end

        # Drop the named view
        def drop_view(view_name)
          execute "DROP VIEW #{quote_table_name(view_name)}"
        end

        # ---
        # these are all expected to be defined by subclasses, listing them
        # here only as templates.
        # +++
        # Returns a list of all views (abstract)
        def views(name = nil) [] end
        # Returns the SQL definition of a given view (abstract)
        def view_definition(view_name, name = nil) end
        # Return the ForeignKeyDefinition objects for foreign key
        # constraints defined on this table (abstract)
        def foreign_keys(table_name, name = nil) [] end
        # Return the ForeignKeyDefinition objects for foreign key
        # constraints defined on other tables that reference this table
        # (abstract)
        def reverse_foreign_keys(table_name, name = nil) [] end

        # Define a foreign key constraint
        def add_foreign_key(table_name, column_names, references_table_name, references_column_names, options = {})
          foreign_key = ForeignKeyDefinition.new(options[:name], table_name, column_names, ::ActiveRecord::Migrator.proper_table_name(references_table_name), references_column_names, options[:on_update], options[:on_delete], options[:deferrable])
          execute "ALTER TABLE #{quote_table_name(table_name)} ADD #{foreign_key.to_sql}"
        end

        # Remove a foreign key constraint
        def remove_foreign_key(table_name, foreign_key_name, options = {})
          execute "ALTER TABLE #{quote_table_name(table_name)} DROP CONSTRAINT #{foreign_key_name}"
        end

        def drop_table_with_schema_plus(name, options = {}) #:nodoc:
          unless ::ActiveRecord::Base.connection.class.include?(SchemaPlus::ActiveRecord::ConnectionAdapters::Sqlite3Adapter)
            reverse_foreign_keys(name).each { |foreign_key| remove_foreign_key(foreign_key.table_name, foreign_key.name, options) }
          end
          drop_table_without_schema_plus(name, options)
        end

        # Returns true if the database supports parital indexes (abstract; only
        # Postgresql returns true)
        def supports_partial_indexes?
          false
        end

      end
    end
  end
end
