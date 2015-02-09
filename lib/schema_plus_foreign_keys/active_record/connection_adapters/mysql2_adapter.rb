module SchemaPlusForeignKeys
  module ActiveRecord
    module ConnectionAdapters
      # SchemaPlusForeignKeys includes a MySQL implementation of the AbstractAdapter
      # extensions.
      module Mysql2Adapter

        #:enddoc:

        def remove_column(table_name, column_name, type=nil, options={})
          foreign_keys(table_name).select { |foreign_key| Array.wrap(foreign_key.column).include?(column_name.to_s) }.each do |foreign_key|
            remove_foreign_key(table_name, name: foreign_key.name)
          end
          super table_name, column_name, type, options
        end

        def rename_table(oldname, newname)
          super
          rename_foreign_keys(oldname, newname)
        end

        def remove_foreign_key(*args)
          from_table, to_table, options = normalize_remove_foreign_key_args(*args)
          if options[:if_exists]
            foreign_key_name = get_foreign_key_name(from_table, to_table, options)
            return if !foreign_key_name or not foreign_keys(from_table).detect{|fk| fk.name == foreign_key_name}
          end
          options.delete(:if_exists)
          super from_table, to_table, options
        end

        def remove_foreign_key_sql(*args)
          super.tap { |ret|
            ret.sub!(/DROP CONSTRAINT/, 'DROP FOREIGN KEY') if ret
          }
        end

        def foreign_keys(table_name, name = nil)
          results = select_all("SHOW CREATE TABLE #{quote_table_name(table_name)}", name)

          table_name = table_name.to_s
          namespace_prefix = table_namespace_prefix(table_name)

          foreign_keys = []

          results.each do |result|
            create_table_sql = result["Create Table"]
            create_table_sql.lines.each do |line|
              if line =~ /^  CONSTRAINT [`"](.+?)[`"] FOREIGN KEY \([`"](.+?)[`"]\) REFERENCES [`"](.+?)[`"] \((.+?)\)( ON DELETE (.+?))?( ON UPDATE (.+?))?,?$/
                name = $1
                columns = $2
                to_table = $3
                to_table = namespace_prefix + to_table if table_namespace_prefix(to_table).blank?
                primary_keys = $4
                on_update = $8
                on_delete = $6
                on_update = ForeignKeyDefinition::ACTION_LOOKUP[on_update] || :restrict
                on_delete = ForeignKeyDefinition::ACTION_LOOKUP[on_delete] || :restrict

                options = { :name => name,
                            :on_delete => on_delete,
                            :on_update => on_update,
                            :column => columns.gsub('`', '').split(', '),
                            :primary_key => primary_keys.gsub('`', '').split(', ')
                }

                foreign_keys << ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
                  namespace_prefix + table_name,
                  to_table,
                  options)
              end
            end
          end

          foreign_keys
        end

        def reverse_foreign_keys(table_name, name = nil)
          results = select_all(<<-SQL, name)
        SELECT constraint_name, table_name, column_name, referenced_table_name, referenced_column_name
          FROM information_schema.key_column_usage
         WHERE table_schema = #{table_schema_sql(table_name)}
           AND referenced_table_schema = table_schema
         ORDER BY constraint_name, ordinal_position;
          SQL

          constraints = results.to_a.group_by do |r|
            r.values_at('constraint_name', 'table_name', 'referenced_table_name')
          end

          from_table_constraints = constraints.select do |(_, _, to_table), _|
            table_name_without_namespace(table_name).casecmp(to_table) == 0
          end

          from_table_constraints.map do |(constraint_name, from_table, to_table), columns|
            from_table = table_namespace_prefix(from_table) + from_table
            to_table = table_namespace_prefix(to_table) + to_table

            options = {
              :name => constraint_name,
              :column => columns.map { |row| row['column_name'] },
              :primary_key => columns.map { |row| row['referenced_column_name'] }
            }

            ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(from_table, to_table, options)
          end
        end

        private

        def table_namespace_prefix(table_name)
          table_name.to_s =~ /(.*[.])/ ? $1 : ""
        end

        def table_schema_sql(table_name)
          table_name.to_s =~ /(.*)[.]/ ? "'#{$1}'" : "SCHEMA()"
        end

        def table_name_without_namespace(table_name)
          table_name.to_s.sub /.*[.]/, ''
        end

      end
    end
  end
end
