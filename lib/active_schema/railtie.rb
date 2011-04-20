module ActiveSchema
  class Railtie < Rails::Railtie
    config.before_initialize do
      ActiveSchema.insert_connection_adapters
    end

    initializer 'active_schema.insert', :after => :load_config_initializers do
      ActiveSchema.insert
    end

  end
end
