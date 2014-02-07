module SchemaPlus
  module ActiveRecord
    # SchemaPlus adds several methods to the connection adapter (as returned by ActiveRecordBase#connection).  See AbstractAdapter for details.
    module ConnectionAdapters

      #
      # SchemaPlus adds several methods to
      # ActiveRecord::ConnectionAdapters::AbstractAdapter.  In most cases
      # you don't call these directly, but rather the methods that define
      # things are called by schema statements, and methods that query
      # things are called by ActiveRecord::Base.
      #
      module AbstractAdapter
        def self.included(base) #:nodoc:
          base.alias_method_chain :initialize, :schema_plus
          base.alias_method_chain :remove_index, :schema_plus
        end

        def initialize_with_schema_plus(*args) #:nodoc:
          initialize_without_schema_plus(*args)
          adapter = case adapter_name
                      # name of MySQL adapter depends on mysql gem
                      # * with mysql gem adapter is named MySQL
                      # * with mysql2 gem adapter is named Mysql2
                      # Here we handle this and hopefully futher adapter names
                    when /^MySQL/i                 then 'MysqlAdapter'
                    when 'PostgreSQL', 'PostGIS'   then 'PostgresqlAdapter'
                    when 'SQLite'                  then 'Sqlite3Adapter'
                    end
          unless adapter
            ::ActiveRecord::Base.logger.warn "SchemaPlus: Unsupported adapter name #{adapter_name.inspect}.  Leaving it alone."
            return
          end
          adapter_module = SchemaPlus::ActiveRecord::ConnectionAdapters.const_get(adapter)
          self.class.send(:include, adapter_module) unless self.class.include?(adapter_module)

          if "#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}".to_r >= "4.1".to_r
            self.class.const_get(:SchemaCreation).send(:include, adapter_module.const_get(:AddColumnOptions))
          else
            self.class.send(:include, adapter_module.const_get(:AddColumnOptions))
          end

          extend(SchemaPlus::ActiveRecord::ForeignKeys)
        end

        # Create a view given the SQL definition.  Specify :force => true
        # to first drop the view if it already exists.
        def create_view(view_name, definition, options={})
          definition = definition.to_sql if definition.respond_to? :to_sql
          execute "DROP VIEW IF EXISTS #{quote_table_name(view_name)}" if options[:force]
          execute "CREATE VIEW #{quote_table_name(view_name)} AS #{definition}"
        end

        # Drop the named view
        def drop_view(view_name)
          execute "DROP VIEW #{quote_table_name(view_name)}"
        end


        # Define a foreign key constraint.  Valid options are :on_update,
        # :on_delete, and :deferrable, with values as described at
        # ConnectionAdapters::ForeignKeyDefinition
        #
        # (NOTE: Sqlite3 does not support altering a table to add foreign-key
        # constraints; they must be included in the table specification when
        # it's created.  If you're using Sqlite3, this method will raise an
        # error.)
        def add_foreign_key(table_name, column_names, references_table_name, references_column_names, options = {})
          foreign_key_sql = add_foreign_key_sql(table_name, column_names, references_table_name, references_column_names, options)
          execute "ALTER TABLE #{quote_table_name(table_name)} #{foreign_key_sql}"
        end

        # called directly by AT's bulk_change_table, for migration
        # change_table :name, :bulk => true { ... }
        def add_foreign_key_sql(table_name, column_names, references_table_name, references_column_names, options = {}) #:nodoc:
          foreign_key = _build_foreign_key(table_name, column_names, references_table_name, references_column_names, options)
          "ADD #{foreign_key.to_sql}"
        end

        def _build_foreign_key(table_name, column_names, references_table_name, references_column_names, options = {}) #:nodoc:
          ForeignKeyDefinition.new(options[:name] || ForeignKeyDefinition.default_name(table_name, column_names), table_name, column_names, AbstractAdapter.proper_table_name(references_table_name), references_column_names, options[:on_update], options[:on_delete], options[:deferrable])
        end

        def self.proper_table_name(name)
           if ::ActiveRecord::Migration.instance_methods(false).include? :proper_table_name
           proper_name = ::ActiveRecord::Migration.new.proper_table_name(name) # Rails >= 4.1
         else
           proper_name = ::ActiveRecord::Migrator.proper_table_name(name) # Rails <= 4.0 ; Deprecated in 4.1
         end
        end

        # Remove a foreign key constraint
        #
        # Arguments are the same as for add_foreign_key, or by name:
        #
        #    remove_foreign_key table_name, column_names, references_table_name, references_column_names
        #    remove_foreign_key name: constraint_name
        #
        # (NOTE: Sqlite3 does not support altering a table to remove
        # foreign-key constraints.  If you're using Sqlite3, this method will
        # raise an error.)
        def remove_foreign_key(table_name, *args)
          case sql = remove_foreign_key_sql(table_name, *args)
          when String then execute "ALTER TABLE #{quote_table_name(table_name)} #{sql}"
          end
        end

        def remove_foreign_key_sql(table_name, *args)
          column_names, references_table_name, references_column_names, options = args
          options ||= {}
          foreign_key_name = case
                             when args.length == 1
                               case args[0]
                               when Hash then   args[0][:name]
                               else args[0]
                               end
                             else
                               test_fk = _build_foreign_key(table_name, column_names, references_table_name, references_column_names, options)
                               if foreign_keys(table_name).detect { |fk| fk == test_fk }
                                 test_fk.name
                               else
                                 raise "SchemaPlus: no foreign key constraint found on #{table_name.inspect} matching #{args.inspect}" unless options[:if_exists]
                                 nil
                               end
                             end
          foreign_key_name ? "DROP CONSTRAINT #{foreign_key_name}" : []  # hack -- return empty array rather than nil, so that result will disappear when caller flattens but doesn't compact
        end

        # Extends rails' drop_table to include these options:
        #   :cascade
        #   :if_exists
        #
        def drop_table(name, options = {})
          sql = "DROP TABLE"
          sql += " IF EXISTS" if options[:if_exists]
          sql += " #{quote_table_name(name)}"
          sql += " CASCADE" if options[:cascade]
          execute sql
        end

        # Extends rails' remove_index to include this options:
        #   :if_exists
        def remove_index_with_schema_plus(table_name, *args)
          options = args.extract_options!
          if_exists = options.delete(:if_exists)
          options.delete(:column) if options[:name] and ::ActiveRecord::VERSION::MAJOR < 4
          args << options if options.any?
          return if if_exists and not index_name_exists?(table_name, options[:name] || index_name(table_name, *args), false)
          remove_index_without_schema_plus(table_name, *args)
        end

        # called from individual adpaters, after renaming table from old
        # name to
        def rename_indexes_and_foreign_keys(oldname, newname) #:nodoc:
          indexes(newname).select{|index| index.name == index_name(oldname, index.columns)}.each do |index|
            rename_index(newname, index.name, index_name(newname, index.columns))
          end
          foreign_keys(newname).each do |fk|
            index = indexes(newname).find{|index| index.name == ForeignKeyDefinition.auto_index_name(oldname, fk.column_names)}
            begin
              remove_foreign_key(newname, fk.name)
            rescue NotImplementedError
              # sqlite3 can't remove foreign keys, so just skip it
            end
            # rename the index only when the fk constraint doesn't exist.
            # mysql doesn't allow the rename (which is a delete & add)
            # if the index is on a foreign key constraint
            rename_index(newname, index.name, ForeignKeyDefinition.auto_index_name(newname, index.columns)) if index
            begin
              add_foreign_key(newname, fk.column_names, fk.references_table_name, fk.references_column_names, :name => fk.name.sub(/#{oldname}/, newname), :on_update => fk.on_update, :on_delete => fk.on_delete, :deferrable => fk.deferrable)
            rescue NotImplementedError
              # sqlite3 can't add foreign keys, so just skip it
            end
          end
        end

        # Returns true if the database supports parital indexes (abstract; only
        # Postgresql returns true)
        def supports_partial_indexes?
          false
        end

        module AddColumnOptions
          def self.included(base) #:nodoc:
            base.alias_method_chain :add_column_options!, :schema_plus
          end

          def add_column_options_with_schema_plus!(sql, options)
            if options_include_default?(options)
              default = options[:default]

              if default.is_a? Hash
                value = default[:value]
                expr = sql_for_function(default[:expr]) || default[:expr] if default[:expr]
              else
                value = default
                expr = sql_for_function(default)
              end

              if expr
                raise ArgumentError, "Invalid default expression" unless default_expr_valid?(expr)
                sql << " DEFAULT #{expr}"
                # must explicitly check for :null to allow change_column to work on migrations
                if options[:null] == false
                  sql << " NOT NULL"
                end
              else
                add_column_options_without_schema_plus!(sql, options.merge(default: value))
              end
            else
              add_column_options_without_schema_plus!(sql, options)
            end
          end

          #####################################################################
          #
          # The functions below here are abstract; each subclass should
          # define them all. Defining them here only for reference.

          # (abstract) Return true if the passed expression can be used as a column
          # default value.  (For most databases the specific expression
          # doesn't matter, and the adapter's function would return a
          # constant true if default expressions are supported or false if
          # they're not.)
          def default_expr_valid?(expr) raise "Internal Error: Connection adapter didn't override abstract function"; end

          # (abstract) Return SQL definition for a given canonical function_name symbol.
          # Currently, the only function to support is :now, which should
          # return a DATETIME object for the current time.
          def sql_for_function(function_name) raise "Internal Error: Connection adapter didn't override abstract function"; end
        end

        module VisitTableDefinition
          def self.included(base) #:nodoc:
            base.alias_method_chain :visit_TableDefinition, :schema_plus
          end

          def visit_TableDefinition_with_schema_plus(o) #:nodoc:
            create_sql = visit_TableDefinition_without_schema_plus(o)
            last_chunk = ") #{o.options}"

            unless create_sql.end_with?(last_chunk)
              raise "Internal Error: Can't find '#{last_chunk}' at end of '#{create_sql}' - Rails internals have changed!"
            end

            unless o.foreign_keys.empty?
              create_sql[create_sql.size - last_chunk.size, 0] = ', ' + o.foreign_keys.map(&:to_sql) * ', '
            end
            create_sql
          end
        end

        #####################################################################
        #
        # The functions below here are abstract; each subclass should
        # define them all. Defining them here only for reference.
        #

        # (abstract) Returns the names of all views, as an array of strings
        def views(name = nil) raise "Internal Error: Connection adapter didn't override abstract function"; [] end

        # (abstract) Returns the SQL definition of a given view.  This is
        # the literal SQL would come after 'CREATVE VIEW viewname AS ' in
        # the SQL statement to create a view.
        def view_definition(view_name, name = nil) raise "Internal Error: Connection adapter didn't override abstract function"; end

        # (abstract) Return the ForeignKeyDefinition objects for foreign key
        # constraints defined on this table
        def foreign_keys(table_name, name = nil) raise "Internal Error: Connection adapter didn't override abstract function"; [] end

        # (abstract) Return the ForeignKeyDefinition objects for foreign key
        # constraints defined on other tables that reference this table
        def reverse_foreign_keys(table_name, name = nil) raise "Internal Error: Connection adapter didn't override abstract function"; [] end
      end
    end
  end
end
