module SchemaPlus
  class Railtie < Rails::Railtie #:nodoc:

    initializer 'schema_plus.insert', :after => "active_record.initialize_database" do
      ActiveSupport.on_load(:active_record) do
        SchemaPlus.insert
      end
    end

    rake_tasks do
      load 'rails/tasks/database.rake'
      if task = Rake.application.tasks.find { |task| task.name == 'db:schema:dump' }
        task.enhance(["schema_plus:load"])
      end
    end

    config.app_generators.indexes false

  end
end
