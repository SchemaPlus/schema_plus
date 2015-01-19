module SchemaColumnPlus
  module Middleware
    module Model

      def self.insert
        SchemaMonkey::Middleware::Model::Columns.append AddModels
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
    end
  end
end
