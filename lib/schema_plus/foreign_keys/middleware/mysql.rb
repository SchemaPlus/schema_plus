module SchemaPlus::ForeignKeys
  module Middleware

    module Mysql
      module Migration
        module DropTable

          def around(env)
            if (env.options[:force] == :cascade)
              env.connection.reverse_foreign_keys(env.table_name).each do |foreign_key|
                env.connection.remove_foreign_key(foreign_key.from_table, name: foreign_key.name)
              end
            end
            yield env
          end
        end
      end
    end
  end
end
