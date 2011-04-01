module ActiveSchema
  class Railtie < Rails::Railtie

    initializer 'active_schema.insert', :after => :load_config_initializers do
      ActiveSupport.on_load :active_record do
        ActiveSchema.insert
      end
    end

  end
end
