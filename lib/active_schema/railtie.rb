require 'rails'

module ActiveSchema
  class Railtie < Rails::Railtie

    config.after_initialize do
      ActiveSupport.on_load :active_record do
        ActiveSchema.insert_into_active_record
      end
    end

  end
end
