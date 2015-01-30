module SchemaPlusViews
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter

        def views(name = nil) #:nodoc:
          sql = <<-SQL
            SELECT viewname
              FROM pg_views
            WHERE schemaname = ANY (current_schemas(false))
            AND viewname NOT LIKE 'pg\_%'
          SQL
          sql += " AND schemaname != 'postgis'" if adapter_name == 'PostGIS'
          query(sql, name).map { |row| row[0] }
        end

        def view_definition(view_name, name = nil) #:nodoc:
          result = query(<<-SQL, name)
        SELECT pg_get_viewdef(oid)
          FROM pg_class
         WHERE relkind = 'v'
           AND relname = '#{view_name}'
          SQL
          row = result.first
          row.first.chomp(';') unless row.nil?
        end

      end
    end
  end
end
