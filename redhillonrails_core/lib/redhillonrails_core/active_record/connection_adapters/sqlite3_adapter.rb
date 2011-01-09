module RedhillonrailsCore
  module ActiveRecord
    module ConnectionAdapters
      module Sqlite3Adapter
        def self.included(base)
          base.class_eval do
            alias_method_chain :tables, :redhillonrails_core
          end
        end

        def move_table(from, to, options = {}, &block) #:nodoc:
          copy_table(from, to, options, &block)
          drop_table(from, options)
        end

        def add_foreign_key(from_table_name, from_column_names, to_table_name, to_column_names, options = {})
          initialize_sqlite3_foreign_key_table
          from_column_names = Array(from_column_names)
          to_column_names = Array(to_column_names)
          fk_name = options[:name] || ["fk", from_table_name, *to_column_names].join("_")

          columns = %w(name from_table_name from_column_names to_table_name to_column_names)
          values = [fk_name, from_table_name, from_column_names.join(","), to_table_name, to_column_names.join(",")]

          quoted_values = values.map { |x| quote(x.to_s) }.join(",")

          # TODO: support options

          insert <<-SQL
        INSERT INTO #{sqlite3_foreign_key_table}(#{quoted_columns(columns)})
        VALUES (#{quoted_values})
          SQL
        end

        def remove_foreign_key(table_name, foreign_key_name, options = {})
          return if options[:temporary] == true
          initialize_sqlite3_foreign_key_table

          rows_deleted = delete <<-SQL
        DELETE FROM #{sqlite3_foreign_key_table}
         WHERE #{quote_column_name("name")} = #{quote(foreign_key_name.to_s)}
           AND #{quote_column_name("from_table_name")} = #{quote(table_name.to_s)}
           SQL

           if rows_deleted != 1
             raise ActiveRecord::ActiveRecordError, "Foreign-key '#{foreign_key_name}' on table '#{table_name}' not found"
           end
        end

        def tables_with_redhillonrails_core(name=nil)
          tables_without_redhillonrails_core.reject{ |name| name == sqlite3_foreign_key_table }
        end

        def foreign_keys(table_name, name = nil)
          load_foreign_keys("from_table_name", table_name, name)
        end

        def reverse_foreign_keys(table_name, name = nil)
          load_foreign_keys("to_table_name", table_name, name)
        end

        private

        def quoted_columns(columns)
          columns.map { |x| quote_column_name(x) }.join(",")
        end

        def sqlite3_foreign_key_table
          "sqlite3_foreign_keys"
        end

        def initialize_sqlite3_foreign_key_table
          unless sqlite3_foreign_key_table_exists?
            create_table(sqlite3_foreign_key_table, :id => false) do |t|
              t.string "name",              :null => false
              t.string "from_table_name",   :null => false
              t.string "from_column_names", :null => false
              t.string "to_table_name",     :null => false
              t.string "to_column_names",   :null => false
            end
            add_index(sqlite3_foreign_key_table, "name",            :unique => true)
            add_index(sqlite3_foreign_key_table, "from_table_name", :unique => false)
            add_index(sqlite3_foreign_key_table, "to_table_name",   :unique => false)
          end
        end

        def sqlite3_foreign_key_table_exists?
          tables_without_redhillonrails_core.detect { |name| name == sqlite3_foreign_key_table }
        end

        def load_foreign_keys(discriminating_column, table_name, name = nil)
          rows = select_all(<<-SQL, name)
        SELECT *
          FROM #{sqlite3_foreign_key_table}
         WHERE #{quote_column_name(discriminating_column)} = #{quote(table_name.to_s)}
         SQL

         rows.map do |row|
           ForeignKeyDefinition.new(
             row["name"],
             row["from_table_name"], row["from_column_names"].split(","),
             row["to_table_name"], row["to_column_names"].split(",")
           )
         end
        end

      end

    end
  end
end
