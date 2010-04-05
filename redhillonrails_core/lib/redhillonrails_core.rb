begin 
  require 'active_record'
rescue
  gem 'active_record'
  require 'active_record'
end

# TODO: only needed adapters should be required here
require 'active_record/connection_adapters/postgresql_adapter'
require 'active_record/connection_adapters/mysql_adapter'
require 'active_record/connection_adapters/sqlite3_adapter'
require 'red_hill_consulting/core'
require 'red_hill_consulting/core/active_record'
require 'red_hill_consulting/core/active_record/base'
require 'red_hill_consulting/core/active_record/schema'
require 'red_hill_consulting/core/active_record/schema_dumper'
require 'red_hill_consulting/core/active_record/connection_adapters/abstract_adapter'
require 'red_hill_consulting/core/active_record/connection_adapters/foreign_key_definition'
require 'red_hill_consulting/core/active_record/connection_adapters/column'
require 'red_hill_consulting/core/active_record/connection_adapters/index_definition'
require 'red_hill_consulting/core/active_record/connection_adapters/mysql_adapter'
require 'red_hill_consulting/core/active_record/connection_adapters/mysql_column'
require 'red_hill_consulting/core/active_record/connection_adapters/postgresql_adapter'
require 'red_hill_consulting/core/active_record/connection_adapters/schema_statements'
require 'red_hill_consulting/core/active_record/connection_adapters/sqlite3_adapter'
require 'red_hill_consulting/core/active_record/connection_adapters/table_definition'

ActiveRecord::Base.send(:include, RedHillConsulting::Core::ActiveRecord::Base)
ActiveRecord::Schema.send(:include, RedHillConsulting::Core::ActiveRecord::Schema)
ActiveRecord::SchemaDumper.send(:include, RedHillConsulting::Core::ActiveRecord::SchemaDumper)
ActiveRecord::ConnectionAdapters::IndexDefinition.send(:include, RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::IndexDefinition)
ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::TableDefinition)
ActiveRecord::ConnectionAdapters::Column.send(:include, RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::Column)
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::AbstractAdapter)
ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::SchemaStatements)

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send(:include, RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::PostgresqlAdapter)

ActiveRecord::ConnectionAdapters::MysqlColumn.send(:include, RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::MysqlColumn)
ActiveRecord::ConnectionAdapters::MysqlAdapter.send(:include, RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::MysqlAdapter)
if ActiveRecord::Base.connection.send(:version)[0] < 5
  #include MySql4Adapter
  ActiveRecord::ConnectionAdapters::MysqlAdapter.send(:include, RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::Mysql4Adapter)
else
  #include MySql5Adapter
  ActiveRecord::ConnectionAdapters::MysqlAdapter.send(:include, RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::Mysql5Adapter)
end

ActiveRecord::ConnectionAdapters::SQLite3Adapter.send(:include, RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::Sqlite3Adapter)
