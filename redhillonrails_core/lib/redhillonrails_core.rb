begin 
  require 'active_record'
rescue
  gem 'active_record'
  require 'active_record'
end

# TODO: only needed adapters should be required here
require 'redhillonrails_core/active_record/base'
require 'redhillonrails_core/active_record/schema'
require 'redhillonrails_core/active_record/schema_dumper'
require 'redhillonrails_core/active_record/connection_adapters/abstract_adapter'
require 'redhillonrails_core/active_record/connection_adapters/foreign_key_definition'
require 'redhillonrails_core/active_record/connection_adapters/column'
require 'redhillonrails_core/active_record/connection_adapters/index_definition'
require 'redhillonrails_core/active_record/connection_adapters/mysql_column'
require 'redhillonrails_core/active_record/connection_adapters/table_definition'

module RedhillonrailsCore::ActiveRecord::ConnectionAdapters
  autoload :MysqlAdapter, 'redhillonrails_core/active_record/connection_adapters/mysql_adapter'
  autoload :PostgresqlAdapter, 'redhillonrails_core/active_record/connection_adapters/postgresql_adapter'
  autoload :Sqlite3Adapter, 'redhillonrails_core/active_record/connection_adapters/sqlite3_adapter'
end

ActiveRecord::Base.send(:include, RedhillonrailsCore::ActiveRecord::Base)
ActiveRecord::Schema.send(:include, RedhillonrailsCore::ActiveRecord::Schema)
ActiveRecord::SchemaDumper.send(:include, RedhillonrailsCore::ActiveRecord::SchemaDumper)
ActiveRecord::ConnectionAdapters::IndexDefinition.send(:include, RedhillonrailsCore::ActiveRecord::ConnectionAdapters::IndexDefinition)
ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, RedhillonrailsCore::ActiveRecord::ConnectionAdapters::TableDefinition)
ActiveRecord::ConnectionAdapters::Column.send(:include, RedhillonrailsCore::ActiveRecord::ConnectionAdapters::Column)
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, RedhillonrailsCore::ActiveRecord::ConnectionAdapters::AbstractAdapter)
