module SchemaPlusForeignKeys
  module Middleware

    module Model
      module ResetColumnInformation

        def after(env)
          env.model.reset_foreign_key_information
        end

      end
    end

  end
end
