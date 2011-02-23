require 'active_support'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_record'

require 'active_schema/version'
require 'active_schema/active_record/base'
require 'active_schema/active_record/migration'
require 'active_schema/active_record/connection_adapters/table_definition'
require 'active_schema/active_record/connection_adapters/schema_statements'
require 'active_schema/active_record/schema'
require 'active_schema/active_record/schema_dumper'
require 'active_schema/active_record/connection_adapters/abstract_adapter'
require 'active_schema/active_record/connection_adapters/column'
require 'active_schema/active_record/connection_adapters/foreign_key_definition'
require 'active_schema/active_record/connection_adapters/index_definition'
require 'active_schema/active_record/connection_adapters/mysql_column'
require 'active_schema/active_record/schema_validations'

module ActiveSchema
  module ActiveRecord
    module ConnectionAdapters
      autoload :MysqlAdapter, 'active_schema/active_record/connection_adapters/mysql_adapter'
      autoload :PostgresqlAdapter, 'active_schema/active_record/connection_adapters/postgresql_adapter'
      autoload :Sqlite3Adapter, 'active_schema/active_record/connection_adapters/sqlite3_adapter'
    end
  end

  # Configuration parameters 
  class Config
    class ForeignKeys
      # Automatically create FK for columns named _id
      cattr_accessor :auto_create
      @@auto_create = true

      # Create an index after creating FK (default false)
      cattr_accessor :auto_index

      # Default FK update action 
      cattr_accessor :on_update

      # Default FK delete action 
      cattr_accessor :on_delete
    end
    cattr_reader :foreign_keys
    @@foreign_keys = ForeignKeys.new

    class Validations
      # Automatically create validations basing on database schema
      cattr_accessor :auto_create
      @@auto_create = false
    end
    cattr_reader :validations
    @@validations = Validations.new
  end

  def self.config
    @@config ||= Config.new
  end

  def self.setup(&block)
    yield config
  end

  def self.options_for_index(index)
    index.is_a?(Hash) ? index : {}
  end

  def self.set_default_update_and_delete_actions!(options)
    options[:on_update] = options.fetch(:on_update, ActiveSchema.config.foreign_keys.on_update)
    options[:on_delete] = options.fetch(:on_delete, ActiveSchema.config.foreign_keys.on_delete)
  end

end

ActiveRecord::Base.send(:include, ActiveSchema::ActiveRecord::Base)
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::AbstractAdapter)
ActiveRecord::ConnectionAdapters::Column.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::Column)
ActiveRecord::ConnectionAdapters::IndexDefinition.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::IndexDefinition)
ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::SchemaStatements)
ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::TableDefinition)
ActiveRecord::Migration.send(:include, ActiveSchema::ActiveRecord::Migration)
ActiveRecord::Schema.send(:include, ActiveSchema::ActiveRecord::Schema)
ActiveRecord::SchemaDumper.send(:include, ActiveSchema::ActiveRecord::SchemaDumper)
