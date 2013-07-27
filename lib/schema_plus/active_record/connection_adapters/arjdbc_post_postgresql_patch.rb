module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter
        def indexes(table_name, name = nil) #:nodoc:
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
            index_keys = indkey.split(" ").map(&:to_i)

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

            # add info on sort order for columns (only desc order is explicitly specified, asc is the default)
            desc_order_columns = kind.scan(/(\w+) DESC/).flatten
            orders = desc_order_columns.any? ? Hash[column_names.map {|column| [column, desc_order_columns.include?(column) ? :desc : :asc]}] : {}

            ::ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, column_names,
                                                                    :name => index_name,
                                                                    :unique => unique,
                                                                    :orders => orders,
                                                                    :conditions => conditions,
                                                                    :case_sensitive => !(expression =~ /lower/i),
                                                                    :kind => kind.downcase == "btree" ? nil : kind,
                                                                    :expression => expression)
          end
        end
      end
    end
  end
end
