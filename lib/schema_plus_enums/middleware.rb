module SchemaPlusEnums
  module Middleware

    module Dumper
      module Extensions

        module Postgresql

          def after(env)
            env.connection.enums.each do |schema, name, values|
              params = [name.inspect]
              params << values.map(&:inspect).join(', ')
              params << ":schema => #{schema.inspect}" if schema != 'public'

              env.extensions << "create_enum #{params.join(', ')}"
            end
          end
        end
      end
    end
  end
end
