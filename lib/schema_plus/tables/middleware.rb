module SchemaPlus::Tables
  module Middleware

    module Migration
      module DropTable

        def before(env)
          if env.options[:cascade]
            ActiveSupport::Deprecation.warn "drop_table option `cascade: true` is deprecated, use `force: :cascade` instead"
            env.options[:force] = :cascade
          end
        end

        def implement(env)
          sql = "DROP"
          sql += ' TEMPORARY' if env.options[:temporary]    # only relevant for mysql
          sql += " TABLE"
          sql += " IF EXISTS" if env.options[:if_exists]    # added by schema_plus
          sql += " #{env.connection.quote_table_name(env.table_name)}"
          sql += " CASCADE" if env.options[:force] == :cascade
          env.connection.execute sql
        end

        module Sqlite3
          def around(env)
            env.options[:force] = nil if (env.options[:force] == :cascade)
            yield env
          end
        end
      end
    end
  end
end
