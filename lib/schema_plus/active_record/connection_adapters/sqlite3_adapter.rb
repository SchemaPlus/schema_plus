module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters
      module SQLiteColumn

        def self.included(base)
          base.alias_method_chain :default_function, :sqlite3 if base.instance_methods.include? :default_function
        end

        def default_function_with_sqlite3
          @default_function ||= "(#{default})" if default =~ /DATETIME/
          default_function_without_sqlite3
        end
      end

      # SchemaPlus includes an Sqlite3 implementation of the AbstractAdapter
      # extensions.  
      module Sqlite3Adapter

        # :enddoc:

        def self.included(base)
          base.class_eval do
            alias_method_chain :rename_table, :schema_plus
          end

          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::Column, SQLiteColumn
        end

        def initialize(*args)
          super
          execute('PRAGMA FOREIGN_KEYS = ON')
        end

        def rename_table_with_schema_plus(oldname, newname) #:nodoc:
          rename_table_without_schema_plus(oldname, newname)
          rename_foreign_keys(oldname, newname)
        end

        def add_foreign_key(table_name, column_names, references_table_name, references_column_names, options = {})
          raise NotImplementedError, "Sqlite3 does not support altering a table to add foreign key constraints (table #{table_name.inspect} column #{column_names.inspect})"
        end

        def remove_foreign_key(table_name, foreign_key_name)
          raise NotImplementedError, "Sqlite3 does not support altering a table to remove foreign key constraints (table #{table_name.inspect} constraint #{foreign_key_name.inspect})"
        end

        def drop_table(name, options={})
          super(name, options.except(:cascade))
        end

        def foreign_keys(table_name, name = nil)
          get_foreign_keys(table_name, name)
        end

        def reverse_foreign_keys(table_name, name = nil)
          get_foreign_keys(nil, name).select{|definition| definition.references_table_name == table_name}
        end

        protected

        def get_foreign_keys(table_name = nil, name = nil)
          results = execute(<<-SQL, name)
            SELECT name, sql FROM sqlite_master
            WHERE type='table' #{table_name && %" AND name='#{table_name}' "}
          SQL

          re = %r[
            \b(CONSTRAINT\s+(\S+)\s+)?
            FOREIGN\s+KEY\s* \(\s*[`"](.+?)[`"]\s*\)
            \s*REFERENCES\s*[`"](.+?)[`"]\s*\((.+?)\)
            (\s+ON\s+UPDATE\s+(.+?))?
            (\s*ON\s+DELETE\s+(.+?))?
            (\s*DEFERRABLE(\s+INITIALLY\s+DEFERRED)?)?
            \s*[,)]
          ]x

          foreign_keys = []
          results.each do |row|
            table_name = row["name"]
            row["sql"].scan(re).each do |d0, name, column_names, references_table_name, references_column_names, d1, on_update, d2, on_delete, deferrable, initially_deferred|
              column_names = column_names.gsub('`', '').split(', ')

              references_column_names = references_column_names.gsub('`"', '').split(', ')
              on_update = on_update ? on_update.downcase.gsub(' ', '_').to_sym : :no_action
              on_delete = on_delete ? on_delete.downcase.gsub(' ', '_').to_sym : :no_action
              deferrable = deferrable ? (initially_deferred ? :initially_deferred : true) : false

              options = { :name => name,
                          :on_update => on_update,
                          :on_delete => on_delete,
                          :column_names => column_names,
                          :references_column_names => references_column_names,
                          :deferrable => deferrable }

              foreign_keys << ForeignKeyDefinition.new(table_name,
                                                       references_table_name,
                                                       options)
            end
          end

          foreign_keys
        end

      end

    end
  end
end
