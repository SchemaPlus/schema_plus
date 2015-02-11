module SchemaPlus::ForeignKeys
  module ActiveRecord
    module ConnectionAdapters

      # The Postgresql adapter implements the SchemaPlus::ForeignKeys extensions and
      # enhancements
      module PostgresqlAdapter

        def rename_table(oldname, newname) #:nodoc:
          super
          rename_foreign_keys(oldname, newname)
        end

        def foreign_keys(table_name, name = nil) #:nodoc:
          load_foreign_keys(<<-SQL, name)
        SELECT f.conname, pg_get_constraintdef(f.oid), t.relname
          FROM pg_class t, pg_constraint f
         WHERE f.conrelid = t.oid
           AND f.contype = 'f'
           AND t.relname = '#{table_name_without_namespace(table_name)}'
           AND t.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = #{namespace_sql(table_name)} )
          SQL
        end

        def reverse_foreign_keys(table_name, name = nil) #:nodoc:
          load_foreign_keys(<<-SQL, name)
        SELECT f.conname, pg_get_constraintdef(f.oid), t2.relname
          FROM pg_class t, pg_class t2, pg_constraint f
         WHERE f.confrelid = t.oid
           AND f.conrelid = t2.oid
           AND f.contype = 'f'
           AND t.relname = '#{table_name_without_namespace(table_name)}'
           AND t.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = #{namespace_sql(table_name)} )
          SQL
        end

        private

        def unquote(name)
          return name.map { |name| unquote(name) } if name.is_a?(Array)
          name.sub(/^["`](.*)["`]$/, '\1')
        end

        def namespace_sql(table_name)
          (table_name.to_s =~ /(.*)[.]/) ?  "'#{$1}'" : "ANY (current_schemas(false))"
        end

        def table_name_without_namespace(table_name)
          table_name.to_s.sub /.*[.]/, ''
        end

        def load_foreign_keys(sql, name = nil) #:nodoc:
          foreign_keys = []

          query(sql, name).each do |row|
            if row[1] =~ /^FOREIGN KEY \((.+?)\) REFERENCES (.+?)\((.+?)\)( ON UPDATE (.+?))?( ON DELETE (.+?))?( (DEFERRABLE|NOT DEFERRABLE)( (INITIALLY DEFERRED|INITIALLY IMMEDIATE))?)?$/
              name = row[0]
              from_table = unquote(row[2])
              columns = unquote($1.split(', '))
              to_table = unquote($2)
              primary_keys = unquote($3.split(', '))
              on_update = $5
              on_delete = $7
              deferrable = $9 == "DEFERRABLE"
              deferrable = :initially_deferred if ($11 == "INITIALLY DEFERRED" )
              on_update = ForeignKeyDefinition::ACTION_LOOKUP[on_update] || :no_action
              on_delete = ForeignKeyDefinition::ACTION_LOOKUP[on_delete] || :no_action

              options = { :name => name,
                          :on_delete => on_delete,
                          :on_update => on_update,
                          :column => columns,
                          :primary_key => primary_keys,
                          :deferrable => deferrable }

              foreign_keys << ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
                from_table,
                to_table.sub(/^"(.*)"$/, '\1'),
                options)
            end
          end

          foreign_keys
        end

      end
    end
  end
end
