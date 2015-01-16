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
          options = options.dup
          options.reverse_merge!(:column_names => column_names, :references_column_names => references_column_names || "id")
          options.reverse_merge!(:name => ForeignKeyDefinition.default_name(table_name, column_names))
          options.reverse_merge!(:references_table_name => references_table_name)
          ForeignKeyDefinition.new(table_name, AbstractAdapter.proper_table_name(options.delete(:references_table_name)), options)
        end

        def self.proper_table_name(name)
          proper_name = ::ActiveRecord::Migration.new.proper_table_name(name)
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
          if sql = remove_foreign_key_sql(table_name, *args)
            execute "ALTER TABLE #{quote_table_name(table_name)} #{sql}"
          end
        end

        def get_foreign_key_name(table_name, *args)
          args = args.dup
          options = args.extract_options!
          return options[:name] if options[:name]

          case
          when args.length == 1
            args[0]
          else
            column_names, references_table_name, references_column_names = args
            test_fk = _build_foreign_key(table_name, column_names, references_table_name, references_column_names, options)
            if fk = foreign_keys(table_name).detect { |fk| fk == test_fk }
              fk.name
            else
              raise "SchemaPlus: no foreign key constraint found on #{table_name.inspect} matching #{(args + [options]).inspect}" unless options[:if_exists]
              nil
            end
          end
        end

        def remove_foreign_key_sql(table_name, *args)
          options = args.dup.extract_options!
          if foreign_key_name = get_foreign_key_name(table_name, *args)
            "DROP CONSTRAINT #{options[:if_exists] ? "IF EXISTS" : ""} #{foreign_key_name}"
          end
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

        # called from individual adpaters, after renaming table from old
        # name to
        def rename_foreign_keys(oldname, newname) #:nodoc:
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
