require 'schema_monkey'

require_relative 'schema_index_plus/middleware'
require_relative 'schema_index_plus/middleware/postgresql_adapter'
require_relative 'schema_index_plus/active_record/connection_adapters/abstract_adapter'
require_relative 'schema_index_plus/active_record/connection_adapters/column'
require_relative 'schema_index_plus/active_record/connection_adapters/index_definition'
require_relative 'schema_index_plus/active_record/base'

module SchemaIndexPlus
  module ActiveRecord
    module ConnectionAdapters
      autoload :MysqlAdapter, 'schema_index_plus/active_record/connection_adapters/mysql_adapter'
      autoload :Sqlite3Adapter, 'schema_index_plus/active_record/connection_adapters/sqlite3_adapter'
    end
  end

  def self.insert
    SchemaMonkey.patch ::ActiveRecord::Base, self
    SchemaMonkey.patch ::ActiveRecord::ConnectionAdapters::Column, self
    SchemaMonkey.patch ::ActiveRecord::ConnectionAdapters::IndexDefinition, self
  end

end

SchemaMonkey.register(SchemaIndexPlus)
