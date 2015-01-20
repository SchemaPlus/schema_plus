module SchemaPgEnums
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter

        def enums
          result = query(<<-SQL)
            SELECT
              N.nspname AS schema_name,
              T.typname AS enum_name,
              E.enumlabel AS enum_label,
              E.enumsortorder AS enum_sort_order
              --array_agg(E.enumlabel ORDER BY enumsortorder) AS labels
            FROM pg_type T
            JOIN pg_enum E ON E.enumtypid = T.oid
            JOIN pg_namespace N ON N.oid = T.typnamespace
            ORDER BY 1, 2, 4
          SQL

          result.reduce([]) do |res, row|
            last = res.last
            if last && last[0] == row[0] && last[1] == row[1]
              last[2] << row[2]
            else
              res << (row[0..1] << [row[2]])
            end
            res
          end
        end

        def create_enum(name, *values)
          options = values.extract_options!
          list = values.map { |value| escape_enum_value(value) }
          execute "CREATE TYPE #{enum_name(name, options[:schema])} AS ENUM (#{list.join(',')})"
        end

        def alter_enum(name, value, options = {})
          opts = case
                 when options[:before] then "BEFORE #{escape_enum_value(options[:before])}"
                 when options[:after] then "AFTER #{escape_enum_value(options[:after])}"
                 else
                   ''
                 end
          execute "ALTER TYPE #{enum_name(name, options[:schema])} ADD VALUE #{escape_enum_value(value)} #{opts}"
        end

        def drop_enum(name, options = {})
          execute "DROP TYPE #{enum_name(name, options[:schema])}"
        end

        private

        def enum_name(name, schema)
          [schema || 'public', name].map { |s|
            %Q{"#{s}"}
          }.join('.')
        end

        def escape_enum_value(value)
          escaped_value = value.sub("'", "''")
          "'#{escaped_value}'"
        end


      end
    end
  end
end

