module SchemaPlus
  class Railtie < Rails::Railtie
    config.before_initialize do
      SchemaPlus.insert_connection_adapters
    end

    initializer 'schema_plus.insert', :after => :load_config_initializers do
      SchemaPlus.insert
    end

  end
end
