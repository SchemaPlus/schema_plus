require 'valuable'

require 'schema_plus/version'
require 'schema_plus/active_record/base'
require 'schema_plus/active_record/migration'
require 'schema_plus/active_record/connection_adapters/table_definition'
require 'schema_plus/active_record/connection_adapters/schema_statements'
require 'schema_plus/active_record/schema'
require 'schema_plus/active_record/schema_dumper'
require 'schema_plus/active_record/connection_adapters/abstract_adapter'
require 'schema_plus/active_record/connection_adapters/column'
require 'schema_plus/active_record/connection_adapters/foreign_key_definition'
require 'schema_plus/active_record/connection_adapters/index_definition'
require 'schema_plus/active_record/associations'
require 'schema_plus/railtie' if defined?(Rails)

module SchemaPlus
  module ActiveRecord

    autoload :Validations, 'schema_plus/active_record/validations'

    module ConnectionAdapters
      autoload :MysqlAdapter, 'schema_plus/active_record/connection_adapters/mysql_adapter'
      autoload :PostgresqlAdapter, 'schema_plus/active_record/connection_adapters/postgresql_adapter'
      autoload :Sqlite3Adapter, 'schema_plus/active_record/connection_adapters/sqlite3_adapter'
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

      # list of association names to create
      has_value :only, :default => nil

      # list of association types to skip
      has_value :except_type, :default => nil

      # list of association types to create
      has_value :only_type, :default => nil

    end
    has_value :associations, :klass => Associations, :default => Associations.new

    class Validations < Valuable
      # Enable schema validations feature
      has_value :enable, :klass => :boolean, :default => true
      # Automatically create validations based on database constraints
      has_value :auto_create, :klass => :boolean, :default => true

      # Auto-validates given fields only
      has_value :only, :default => nil

      # Auto-validates all but given fields
      has_value :except, :default => [:created_at, :updated_at, :created_on, :updated_on]
      
      # list of validation types to skip
      has_value :except_type, :default => nil

      # list of validation types to create
      has_value :only_type, :default => nil

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

  # Returns the global configuration, i.e., the singleton instance of Config
  def self.config
    @config ||= Config.new
  end

  # Initialization block is passed a global Config instance that can be
  # used to configure SchemaPlus behavior.  E.g., if you want to disable
  # automation creation of foreign key constraints for columns name *_id,
  # put the following in config/initializers/schema_plus.rb :
  #
  #    SchemaPlus.setup do |config|
  #       config.foreign_keys.auto_create = false
  #    end
  #
  def self.setup # :yields: config
    yield config
  end

  def self.insert_connection_adapters #:nodoc:
    return if @inserted_connection_adapters
    @inserted_connection_adapters = true
    ::ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, SchemaPlus::ActiveRecord::ConnectionAdapters::AbstractAdapter)
    ::ActiveRecord::ConnectionAdapters::Column.send(:include, SchemaPlus::ActiveRecord::ConnectionAdapters::Column)
    ::ActiveRecord::ConnectionAdapters::IndexDefinition.send(:include, SchemaPlus::ActiveRecord::ConnectionAdapters::IndexDefinition)
    # (mysql2 v0.2.7 uses its own IndexDefinition, which is compatible with the monkey patches; so if that constant exists, include the patches
    ::ActiveRecord::ConnectionAdapters::Mysql2IndexDefinition.send(:include, SchemaPlus::ActiveRecord::ConnectionAdapters::IndexDefinition) if defined? ::ActiveRecord::ConnectionAdapters::Mysql2IndexDefinition
    ::ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, SchemaPlus::ActiveRecord::ConnectionAdapters::SchemaStatements)
    ::ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, SchemaPlus::ActiveRecord::ConnectionAdapters::TableDefinition)
  end

  def self.insert #:nodoc:
    return if @inserted
    @inserted = true
    insert_connection_adapters
    ::ActiveRecord::Base.send(:include, SchemaPlus::ActiveRecord::Base)
    ::ActiveRecord::Migration.send(:include, SchemaPlus::ActiveRecord::Migration)
    ::ActiveRecord::Schema.send(:include, SchemaPlus::ActiveRecord::Schema)
    ::ActiveRecord::SchemaDumper.send(:include, SchemaPlus::ActiveRecord::SchemaDumper)
  end

end
