module SchemaPgEnums
  module Middleware
    module PostgresqlAdapter
      def self.insert
        SchemaMonkey::Middleware::Dumper::Extensions.append CreateEnums
      end
    end

    class CreateEnums < SchemaMonkey::Middleware::Base
      def call(env)
        continue env

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
