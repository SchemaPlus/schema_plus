require 'schema_monkey'

require_relative 'schema_index_plus/middleware'
require_relative 'schema_index_plus/middleware/postgresql'
require_relative 'schema_index_plus/middleware/sqlite3'
require_relative 'schema_index_plus/active_record/connection_adapters/abstract_adapter'
require_relative 'schema_index_plus/active_record/connection_adapters/column'
require_relative 'schema_index_plus/active_record/connection_adapters/index_definition'
require_relative 'schema_index_plus/active_record/base'

module SchemaIndexPlus
  def self.insert
    SchemaMonkey.patch ::ActiveRecord::Base, self
    SchemaMonkey.patch ::ActiveRecord::ConnectionAdapters::Column, self
    SchemaMonkey.patch ::ActiveRecord::ConnectionAdapters::IndexDefinition, self
  end
end

SchemaMonkey.register(SchemaIndexPlus)
