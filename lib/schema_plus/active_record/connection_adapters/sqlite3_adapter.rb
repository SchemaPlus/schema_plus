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

        def self.included(base)
          base.class_eval do
            alias_method_chain :indexes, :schema_plus
            alias_method_chain :rename_table, :schema_plus
          end

          if ::ActiveRecord::VERSION::MAJOR.to_i < 4
            ::ActiveRecord::ConnectionAdapters::SQLiteColumn.send(:include, SQLiteColumn) unless ::ActiveRecord::ConnectionAdapters::SQLiteColumn.include?(SQLiteColumn)
          else
            ::ActiveRecord::ConnectionAdapters::SQLite3Column.send(:include, SQLiteColumn) unless ::ActiveRecord::ConnectionAdapters::SQLite3Column.include?(SQLiteColumn)
          end
        end

        def initialize(*args)
          super
          execute('PRAGMA FOREIGN_KEYS = ON')
        end

        def indexes_with_schema_plus(table_name, name = nil)
          indexes = indexes_without_schema_plus(table_name, name)
          exec_query("SELECT name, sql FROM sqlite_master WHERE type = 'index'").map do |row|
            if (desc_columns = row['sql'].scan(/['"`]?(\w+)['"`]? DESC\b/).flatten).any?
              index = indexes.detect{ |i| i.name == row['name'] }
              index.orders = Hash[index.columns.map {|column| [column, desc_columns.include?(column) ? :desc : :asc]}]
            end
          end
          indexes
        end

        def rename_table_with_schema_plus(oldname, newname) #:nodoc:
          rename_table_without_schema_plus(oldname, newname)
          rename_indexes_and_foreign_keys(oldname, newname)
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

        def views(name = nil)
          execute("SELECT name FROM sqlite_master WHERE type='view'", name).collect{|row| row["name"]}
        end

        def view_definition(view_name, name = nil)
          sql = execute("SELECT sql FROM sqlite_master WHERE type='view' AND name=#{quote(view_name)}", name).collect{|row| row["sql"]}.first
          sql.sub(/^CREATE VIEW \S* AS\s+/im, '') unless sql.nil?
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
              foreign_keys << ForeignKeyDefinition.new(name,
                                                       table_name, column_names,
                                                       references_table_name, references_column_names,
                                                       on_update, on_delete, deferrable)
            end
          end

          foreign_keys
        end

        module AddColumnOptions
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
end
