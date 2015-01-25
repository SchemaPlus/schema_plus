module SchemaPlusIndex
  module Middleware
    module Model

      def self.insert
        SchemaMonkey::Middleware::Model::ResetColumnInformation.append ResetColumnInformation
      end

      class ResetColumnInformation < SchemaMonkey::Middleware::Base
        def call(env)
          continue env
          env.model.reset_index_information
        end
      end
    end
  end
end
