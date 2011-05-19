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
require 'active_schema/active_record/associations'
require 'active_schema/railtie' if defined?(Rails)

module ActiveSchema
  module ActiveRecord

    autoload :Validations, 'active_schema/active_record/validations'

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

      # list of association names to skip
      has_value :except, :default => nil

      # list of association names to create (overrides :except)
      has_value :only, :default => nil

      # list of association types to skip
      has_value :except_type, :default => nil

      # list of association types to create (overrides :except_type)
      has_value :only_type, :default => nil

    end
    has_value :associations, :klass => Associations, :default => Associations.new

    class Validations < Valuable
      # Enable schema validations feature
      has_value :enable, :klass => :boolean, :default => true
      # Automatically create validations based on database constraints
      has_value :auto_create, :klass => :boolean, :default => true

      # Auto-validates given fields only
      has_value :only

      # Auto-validates all but given fields
      has_value :except
    end
    has_value :validations, :klass => Validations, :default => Validations.new


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

  def self.insert_connection_adapters
    return if @inserted_connection_adapters
    @inserted_connection_adapters = true
    ::ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::AbstractAdapter)
    ::ActiveRecord::ConnectionAdapters::Column.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::Column)
    ::ActiveRecord::ConnectionAdapters::IndexDefinition.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::IndexDefinition)
    # (mysql2 v0.2.7 uses its own IndexDefinition, which is compatible with the monkey patches; so if that constant exists, include the patches
    ::ActiveRecord::ConnectionAdapters::Mysql2IndexDefinition.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::IndexDefinition) if defined? ::ActiveRecord::ConnectionAdapters::Mysql2IndexDefinition
    ::ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::SchemaStatements)
    ::ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, ActiveSchema::ActiveRecord::ConnectionAdapters::TableDefinition)
  end

  def self.insert
    return if @inserted
    @inserted = true
    insert_connection_adapters
    ::ActiveRecord::Base.send(:include, ActiveSchema::ActiveRecord::Base)
    ::ActiveRecord::Migration.send(:include, ActiveSchema::ActiveRecord::Migration)
    ::ActiveRecord::Schema.send(:include, ActiveSchema::ActiveRecord::Schema)
    ::ActiveRecord::SchemaDumper.send(:include, ActiveSchema::ActiveRecord::SchemaDumper)
  end

end
