module SchemaPlus
  module Middleware
    module Model

      def self.insert
        SchemaMonkey::Middleware::Model::ResetColumnInformation.append ResetColumnInformation
      end

      class ResetColumnInformation < SchemaMonkey::Middleware::Base
        def call(env)
          continue env
          env.model.instance_variable_set :@foreign_keys, nil
        end
      end
    end
  end
end
