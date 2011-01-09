module RedhillonrailsCore
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter
        def self.included(base)
          base.class_eval do
            remove_method :indexes
          end
        end

        def add_index(table_name, column_name, options = {})
          column_name, options = [], column_name if column_name.is_a?(Hash)
          column_names = Array(column_name)
          if column_names.empty?
            raise ArgumentError, "No columns and :expression missing from options - cannot create index" if options[:expression].blank?
            raise ArgumentError, "Index name not given. Pass :name option" if options[:name].blank?
          end

          index_type = options[:unique] ? "UNIQUE" : ""
          index_name = options[:name] || index_name(table_name, column_names)
          conditions = options[:conditions]

          if column_names.empty? then
            sql = "CREATE #{index_type} INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} #{options[:expression]}"
          else
            quoted_column_names = column_names.map { |e| options[:case_sensitive] == false && e.to_s !~ /_id$/ ? "LOWER(#{quote_column_name(e)})" : quote_column_name(e) }

            sql = "CREATE #{index_type} INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} (#{quoted_column_names.join(", ")})"
            sql += " WHERE (#{ ::ActiveRecord::Base.send(:sanitize_sql, conditions, quote_table_name(table_name)) })" if conditions
          end
          execute sql
        end

        def supports_partial_indexes?
          true
        end

        def indexes(table_name, name = nil)
          schemas = schema_search_path.split(/,/).map { |p| quote(p) }.join(',')
          result = query(<<-SQL, name)
           SELECT distinct i.relname, d.indisunique, d.indkey, m.amname, t.oid, 
                    pg_get_expr(d.indpred, t.oid), pg_get_expr(d.indexprs, t.oid)
             FROM pg_class t, pg_class i, pg_index d, pg_am m
           WHERE i.relkind = 'i'
             AND i.relam = m.oid
             AND d.indexrelid = i.oid
             AND d.indisprimary = 'f'
             AND t.oid = d.indrelid
             AND t.relname = '#{table_name}'
             AND i.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname IN (#{schemas}) )
          ORDER BY i.relname
          SQL

          result.map do |(index_name, is_unique, indkey, kind, oid, conditions, expression)|
            unique = (is_unique == 't')
            index_keys = indkey.split(" ")

            columns = Hash[query(<<-SQL, "Columns for index #{index_name} on #{table_name}")]
            SELECT a.attnum, a.attname
            FROM pg_attribute a
            WHERE a.attrelid = #{oid}
            AND a.attnum IN (#{index_keys.join(",")})
            SQL

            column_names = columns.values_at(*index_keys).compact
            if md = expression.try(:match, /^lower\(\(?([^)]+)\)?(::text)?\)$/i)
              column_names << md[1]
            end
            index = ::ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, index_name, unique, column_names)
            index.conditions = conditions
            index.case_sensitive = !(expression =~ /lower/i)
            index.kind = kind unless kind.downcase == "btree"
            index.expression = expression
            index
          end
        end

        def foreign_keys(table_name, name = nil)
          load_foreign_keys(<<-SQL, name)
        SELECT f.conname, pg_get_constraintdef(f.oid), t.relname
          FROM pg_class t, pg_constraint f
         WHERE f.conrelid = t.oid
           AND f.contype = 'f'
           AND t.relname = '#{table_name}'
          SQL
        end

        def reverse_foreign_keys(table_name, name = nil)
          load_foreign_keys(<<-SQL, name)
        SELECT f.conname, pg_get_constraintdef(f.oid), t2.relname
          FROM pg_class t, pg_class t2, pg_constraint f
         WHERE f.confrelid = t.oid
           AND f.conrelid = t2.oid
           AND f.contype = 'f'
           AND t.relname = '#{table_name}'
          SQL
        end

        def views(name = nil)
          schemas = schema_search_path.split(/,/).map { |p| quote(p) }.join(',')
          query(<<-SQL, name).map { |row| row[0] }
        SELECT viewname
          FROM pg_views
         WHERE schemaname IN (#{schemas})
          SQL
        end

        def view_definition(view_name, name = nil)
          result = query(<<-SQL, name)
        SELECT pg_get_viewdef(oid)
          FROM pg_class
         WHERE relkind = 'v'
           AND relname = '#{view_name}'
          SQL
          row = result.first
          row.first unless row.nil?
        end

        private

        def load_foreign_keys(sql, name = nil)
          foreign_keys = []

          query(sql, name).each do |row|
            if row[1] =~ /^FOREIGN KEY \((.+?)\) REFERENCES (.+?)\((.+?)\)( ON UPDATE (.+?))?( ON DELETE (.+?))?( (DEFERRABLE|NOT DEFERRABLE))?$/
              name = row[0]
              from_table_name = row[2]
              column_names = $1
              references_table_name = $2
              references_column_names = $3
              on_update = $5
              on_delete = $7
              deferrable = $9 == "DEFERRABLE"
              on_update = on_update.downcase.gsub(' ', '_').to_sym if on_update
              on_delete = on_delete.downcase.gsub(' ', '_').to_sym if on_delete

              foreign_keys << ForeignKeyDefinition.new(name,
                                                       from_table_name, column_names.split(', '),
                                                       references_table_name.sub(/^"(.*)"$/, '\1'), references_column_names.split(', '),
                                                       on_update, on_delete, deferrable)
            end
          end

          foreign_keys
        end

        # Converts form like: column1, LOWER(column2)
        # to: column1, column2
        def determine_index_column_names(column_definitions)
          column_definitions.split(", ").map do |name|
            name = $1 if name =~ /^LOWER\(([^:]+)(::text)?\)$/i
            name = $1 if name =~ /^"(.*)"$/
              name
          end
        end

      end
    end
  end
end
