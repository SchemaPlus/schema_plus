require 'valuable'

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
require 'active_schema/active_record/associations'
require 'active_schema/railtie'

module ActiveSchema
  module ActiveRecord
    module ConnectionAdapters
      autoload :MysqlAdapter, 'active_schema/active_record/connection_adapters/mysql_adapter'
      autoload :PostgresqlAdapter, 'active_schema/active_record/connection_adapters/postgresql_adapter'
      autoload :Sqlite3Adapter, 'active_schema/active_record/connection_adapters/sqlite3_adapter'
    end
  end

  # Configuration parameters 
  class Config < Valuable

    class ForeignKeys < Valuable
      # Automatically create FK for columns named _id
      has_value :auto_create, :klass => :boolean, :default => true

      # Create an index after creating FK
      has_value :auto_index, :klass => :boolean, :default => true

      # Default FK update action 
      has_value :on_update

      # Default FK delete action 
      has_value :on_delete
    end
    has_value :foreign_keys, :klass => ForeignKeys, :default => ForeignKeys.new

    class Associations < Valuable
      # Automatically create associations based on foreign keys
      has_value :auto_create, :klass => :boolean, :default => true

      # Use concise naming (strip out common prefixes from class names)
      has_value :concise_names, :klass => :boolean, :default => true

      # Always create full-name association, i.e. if creating a concise
      # name, also create a second association with the full name.
      has_value :full_names_always, :klass => :boolean, :default => false
    end
    has_value :associations, :klass => Associations, :default => Associations.new


    def dup 
      self.class.new(Hash[attributes.collect{ |key, val| [key, Valuable === val ?  val.class.new(val.attributes) : val] }])
    end

    def update_attributes(opts)
      opts = opts.dup
      opts.keys.each { |key| self.send(key).update_attributes(opts.delete(key)) if self.class.attributes.include? key and Hash === opts[key] }
      super(opts)
      self
    end

    def merge(opts)
      dup.update_attributes(opts)
    end
  end

  def self.config
    @config ||= Config.new
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

  def self.insert_into_active_record
    ::ActiveRecord::Base.send(:include, ActiveSchema::ActiveRecord::Base)
    ::ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::AbstractAdapter)
    ::ActiveRecord::ConnectionAdapters::Column.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::Column)
    ::ActiveRecord::ConnectionAdapters::IndexDefinition.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::IndexDefinition)
    ::ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::SchemaStatements)
    ::ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::TableDefinition)
    ::ActiveRecord::Migration.send(:include, ActiveSchema::ActiveRecord::Migration)
    ::ActiveRecord::Schema.send(:include, ActiveSchema::ActiveRecord::Schema)
    ::ActiveRecord::SchemaDumper.send(:include, ActiveSchema::ActiveRecord::SchemaDumper)
  end

end
