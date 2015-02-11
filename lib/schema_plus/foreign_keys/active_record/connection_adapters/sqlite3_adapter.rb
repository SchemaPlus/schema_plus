module SchemaPlus::ForeignKeys
  module ActiveRecord
    module ConnectionAdapters

      # SchemaPlus::ForeignKeys includes an Sqlite3 implementation of the AbstractAdapter
      # extensions.
      module Sqlite3Adapter

        # :enddoc:

        def initialize(*args)
          super
          execute('PRAGMA FOREIGN_KEYS = ON')
        end

        def rename_table(oldname, newname) #:nodoc:
          super
          rename_foreign_keys(oldname, newname)
        end

        def add_foreign_key(table_name, to_table, options = {})
          raise NotImplementedError, "Sqlite3 does not support altering a table to add foreign key constraints (table #{table_name.inspect} to #{to_table.inspect})"
        end

        def remove_foreign_key(table_name, *args)
          raise NotImplementedError, "Sqlite3 does not support altering a table to remove foreign key constraints (table #{table_name.inspect} constraint #{args.inspect})"
        end

        def foreign_keys(table_name, name = nil)
          get_foreign_keys(table_name, name)
        end

        def reverse_foreign_keys(table_name, name = nil)
          get_foreign_keys(nil, name).select{|definition| definition.to_table == table_name}
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
            from_table = row["name"]
            row["sql"].scan(re).each do |d0, name, columns, to_table, primary_keys, d1, on_update, d2, on_delete, deferrable, initially_deferred|
              columns = columns.gsub(/`/, '').split(', ')

              primary_keys = primary_keys.gsub(/[`"]/, '').split(', ')
              on_update = ForeignKeyDefinition::ACTION_LOOKUP[on_update] || :no_action
              on_delete = ForeignKeyDefinition::ACTION_LOOKUP[on_delete] || :no_action
              deferrable = deferrable ? (initially_deferred ? :initially_deferred : true) : false

              options = { :name => name,
                          :on_update => on_update,
                          :on_delete => on_delete,
                          :column => columns,
                          :primary_key => primary_keys,
                          :deferrable => deferrable }

              foreign_keys << ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
                from_table,
                to_table,
                options)
            end
          end

          foreign_keys
        end

      end

    end
  end
end
