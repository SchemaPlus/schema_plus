module SchemaMonkey
  class Railtie < Rails::Railtie #:nodoc:

    initializer 'schema_monkey.insert', :before => "active_record.initialize_database" do
      ActiveSupport.on_load(:active_record) do
        SchemaMonkey.insert
      end
    end

    rake_tasks do
      load 'rails/tasks/database.rake'
      ['db:schema:dump', 'db:schema:load'].each do |name|
        if task = Rake.application.tasks.find { |task| task.name == name }
          task.enhance(["schema_monkey:load"])
        end
      end
    end

  end
end
