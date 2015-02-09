module SchemaPlusForeignKeys
  module ActiveRecord
    # SchemaPlusForeignKeys adds several methods to the connection adapter (as returned by ActiveRecordBase#connection).  See AbstractAdapter for details.
    module ConnectionAdapters

      #
      # SchemaPlusForeignKeys adds several methods to
      # ActiveRecord::ConnectionAdapters::AbstractAdapter.  In most cases
      # you don't call these directly, but rather the methods that define
      # things are called by schema statements, and methods that query
      # things are called by ActiveRecord::Base.
      #
      module AbstractAdapter

        def create_table(table, options = {})
          options = options.dup
          config_options = options.delete(:foreign_keys) || {}

          # override rails' :force to cascade
          drop_table(table, if_exists: true, cascade: true) if options.delete(:force)

          super(table, options) do |table_definition|
            table_definition.schema_plus_config = SchemaPlusForeignKeys.config.merge(config_options)
            yield table_definition if block_given?
          end
        end

        # Define a foreign key constraint.  Valid options are :on_update,
        # :on_delete, and :deferrable, with values as described at
        # ConnectionAdapters::ForeignKeyDefinition
        #
        # (NOTE: Sqlite3 does not support altering a table to add foreign-key
        # constraints; they must be included in the table specification when
        # it's created.  If you're using Sqlite3, this method will raise an
        # error.)
        def add_foreign_key(*args) # (table_name, column, to_table, primary_key, options = {})
          options = args.extract_options!
          case args.length
          when 2
            from_table, to_table = args
          when 4
            ActiveSupport::Deprecation.warn "4-argument form of add_foreign_key is deprecated.  use add_foreign_key(from_table, to_table, options)"
            (from_table, column, to_table, primary_key) = args
            options.merge!(column: column, primary_key: primary_key)
          end

          options = options.dup
          options[:column] ||= foreign_key_column_for(to_table)

          foreign_key_sql = add_foreign_key_sql(from_table, to_table, options)
          execute "ALTER TABLE #{quote_table_name(from_table)} #{foreign_key_sql}"
        end

        # called directly by AT's bulk_change_table, for migration
        # change_table :name, :bulk => true { ... }
        def add_foreign_key_sql(from_table, to_table, options = {}) #:nodoc:
          foreign_key = ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(from_table, AbstractAdapter.proper_table_name(to_table), options)
          "ADD #{foreign_key.to_sql}"
        end

        def _build_foreign_key(from_table, to_table, options = {}) #:nodoc:
          ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(from_table, AbstractAdapter.proper_table_name(to_table), options)
        end

        def self.proper_table_name(name)
          proper_name = ::ActiveRecord::Migration.new.proper_table_name(name)
        end

        # Remove a foreign key constraint
        #
        # Arguments are the same as for add_foreign_key, or by name:
        #
        #    remove_foreign_key table_name, to_table, options
        #    remove_foreign_key table_name, name: constraint_name
        #
        # (NOTE: Sqlite3 does not support altering a table to remove
        # foreign-key constraints.  If you're using Sqlite3, this method will
        # raise an error.)
        def remove_foreign_key(*args)
          from_table, to_table, options = normalize_remove_foreign_key_args(*args)
          options[:column] ||= foreign_key_column_for(to_table)
          if sql = remove_foreign_key_sql(from_table, to_table, options)
            execute "ALTER TABLE #{quote_table_name(from_table)} #{sql}"
          end
        end

        def normalize_remove_foreign_key_args(*args)
          options = args.extract_options!
          if options.has_key? :column_names
            ActiveSupport::Deprecation.warn ":column_names option is deprecated, use :column"
            options[:column] = options.delete(:column_names)
          end
          if options.has_key? :references_column_names
            ActiveSupport::Deprecation.warn ":references_column_names option is deprecated, use :primary_key"
            options[:primary_key] = options.delete(:references_column_names)
          end
          if options.has_key? :references_table_name
            ActiveSupport::Deprecation.warn ":references_table_name option is deprecated, use :to_table"
            options[:to_table] = options.delete(:references_table_name)
          end
          case args.length
          when 1
            from_table = args[0]
          when 2
            from_table, to_table = args
          when 3, 4
            ActiveSupport::Deprecation.warn "3- and 4-argument forms of remove_foreign_key are deprecated.  use add_foreign_key(from_table, to_table, options)"
            (from_table, column, to_table, primary_key) = args
            options.merge!(column: column, primary_key: primary_key)
          else
            raise ArgumentError, "Wrong number of arguments(args.length) to remove_foreign_key"
          end
          to_table ||= options.delete(:to_table)
          [from_table, to_table, options]
        end

        def get_foreign_key_name(from_table, to_table, options)
          return options[:name] if options[:name]

          fks = foreign_keys(from_table)
          if fks.detect(&its.name == to_table)
            ActiveSupport::Deprecation.warn "remove_foreign_key(table, name) is deprecated.  use remove_foreign_key(table, name: name)"
            return to_table
          end
          test_fk = _build_foreign_key(from_table, to_table, options)
          if fk = fks.detect { |fk| fk.match(test_fk) }
            fk.name
          else
            raise "SchemaPlusForeignKeys: no foreign key constraint found on #{from_table.inspect} matching #{[to_table, options].inspect}" unless options[:if_exists]
            nil
          end
        end

        def remove_foreign_key_sql(from_table, to_table, options)
          if foreign_key_name = get_foreign_key_name(from_table, to_table, options)
            "DROP CONSTRAINT #{options[:if_exists] ? "IF EXISTS" : ""} #{foreign_key_name}"
          end
        end


        # called from individual adpaters, after renaming table from old
        # name to
        def rename_foreign_keys(oldname, newname) #:nodoc:
          foreign_keys(newname).each do |fk|
            index = indexes(newname).find{|index| index.name == ForeignKeyDefinition.auto_index_name(oldname, fk.column)}
            begin
              remove_foreign_key(newname, name: fk.name)
            rescue NotImplementedError
              # sqlite3 can't remove foreign keys, so just skip it
            end
            # rename the index only when the fk constraint doesn't exist.
            # mysql doesn't allow the rename (which is a delete & add)
            # if the index is on a foreign key constraint
            rename_index(newname, index.name, ForeignKeyDefinition.auto_index_name(newname, index.columns)) if index
            begin
              add_foreign_key(newname, fk.to_table, :column => fk.column, :primary_key => fk.primary_key, :name => fk.name.sub(/#{oldname}/, newname), :on_update => fk.on_update, :on_delete => fk.on_delete, :deferrable => fk.deferrable)
            rescue NotImplementedError
              # sqlite3 can't add foreign keys, so just skip it
            end
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
