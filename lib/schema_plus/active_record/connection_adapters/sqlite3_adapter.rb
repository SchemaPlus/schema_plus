module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters
      module SQLiteColumn
        def initialize(name, default, sql_type = nil, null = true)
          if default =~ /DATETIME/
            @default_expr = "(#{default})"
          end
          super(name, default, sql_type, null)
        end
      end

      # SchemaPlus includes an Sqlite3 implementation of the AbstractAdapter
      # extensions.  
      module Sqlite3Adapter

        # :enddoc:

        def add_foreign_key(table_name, column_names, references_table_name, references_column_names, options = {})
          raise NotImplementedError, "Sqlite3 does not support altering a table to add foreign key constraints (table #{table_name.inspect} column #{column_names.inspect})"
        end

        def remove_foreign_key(table_name, foreign_key_name)
          raise NotImplementedError, "Sqlite3 does not support altering a table to remove foreign key constraints (table #{table_name.inspect} constraint #{foreign_key_name.inspect})"
        end

        def foreign_keys(table_name, name = nil)
          get_foreign_keys(table_name, name)
        end

        def reverse_foreign_keys(table_name, name = nil)
          get_foreign_keys(nil, name).select{|definition| definition.references_table_name == table_name}
        end

        def views(name = nil)
          execute("SELECT name FROM sqlite_master WHERE type='view'", name).collect{|row| row["name"]}
        end

        def view_definition(view_name, name = nil)
          sql = execute("SELECT sql FROM sqlite_master WHERE type='view' AND name=#{quote(view_name)}", name).collect{|row| row["sql"]}.first
          sql.sub(/^CREATE VIEW \S* AS\s+/im, '') unless sql.nil?
        end

        protected

        def post_initialize
          execute('PRAGMA FOREIGN_KEYS = 1')
        end

        def get_foreign_keys(table_name = nil, name = nil)
          results = execute(<<-SQL, name)
            SELECT name, sql FROM sqlite_master
            WHERE type='table' #{table_name && %" AND name='#{table_name}' "}
          SQL

          re = %r[
            \bFOREIGN\s+KEY\s* \(\s*[`"](.+?)[`"]\s*\)
            \s*REFERENCES\s*[`"](.+?)[`"]\s*\((.+?)\)
            (\s+ON\s+UPDATE\s+(.+?))?
            (\s*ON\s+DELETE\s+(.+?))?
            \s*[,)]
          ]x

          foreign_keys = []
          results.each do |row|
            table_name = row["name"]
            row["sql"].scan(re).each do |column_names, references_table_name, references_column_names, d1, on_update, d2, on_delete|
              column_names = column_names.gsub('`', '').split(', ')

              references_column_names = references_column_names.gsub('`"', '').split(', ')
              on_update = on_update ? on_update.downcase.gsub(' ', '_').to_sym : :no_action
              on_delete = on_delete ? on_delete.downcase.gsub(' ', '_').to_sym : :no_action
              foreign_keys << ForeignKeyDefinition.new(nil,
                                                       table_name, column_names,
                                                       references_table_name, references_column_names,
                                                       on_update, on_delete)
            end
          end

          foreign_keys
        end

        def default_expr_valid?(expr)
          true # arbitrary sql is okay
        end

        def sql_for_function(function)
          case function
            when :now
              "(DATETIME('now'))"
          end
        end
      end

    end
  end
end
