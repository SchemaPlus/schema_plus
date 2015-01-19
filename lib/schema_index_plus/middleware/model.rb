module SchemaIndexPlus
  module Middleware
    module Model

      def self.insert
        SchemaMonkey::Middleware::Model::Columns.append AddModels
        SchemaMonkey::Middleware::Model::ResetColumnInformation.append ResetColumnInformation
      end

      class AddModels < SchemaMonkey::Middleware::Base
        def call(env)
          continue env

          env.columns.each do |column|
            column.model = env.model
          end

          env.columns
        end
      end

      class ResetColumnInformation < SchemaMonkey::Middleware::Base
        def call(env)
          continue env
          env.model.instance_variable_set :@indexes, nil
        end
      end
    end
  end
end
