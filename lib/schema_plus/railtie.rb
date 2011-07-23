module SchemaPlus 
  class Railtie < Rails::Railtie #:nodoc:

    initializer 'schema_plus.insert', :after => "active_record.initialize_database" do
      ActiveSupport.on_load(:active_record) do
        SchemaPlus.insert
      end
    end

  end
end
