class ForeignKeyMigrationGenerator < Rails::Generator::NamedBase
  def initialize(runtime_args, runtime_options = {})
    runtime_args << 'create_foreign_keys' if runtime_args.empty?
    super
  end

  def manifest
    foreign_keys = []

    connection = ActiveRecord::Base.connection
    connection.tables.each do |table_name|
      connection.columns(table_name).each do |column|
        references = ActiveRecord::Base.references(table_name, column.name)
        foreign_keys << RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(nil, table_name, column.name, references.first, references.last) if references
      end
    end

    record do |m|
      m.migration_template 'migration.rb', 'db/migrate', :assigns => {
        :migration_name => class_name, :foreign_keys => foreign_keys
      }, :migration_file_name => file_name
    end
  end
end
