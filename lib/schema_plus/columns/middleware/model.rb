module SchemaPlus::Columns
  module Middleware
    module Model

      module Columns

        def after(env)
          env.columns.each do |column|
            column.model = env.model
          end
        end

      end
    end
  end
end
