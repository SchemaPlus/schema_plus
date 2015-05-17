require 'schema_plus/foreign_keys'

require_relative 'auto_foreign_keys/active_record/migration/command_recorder'
require_relative 'auto_foreign_keys/middleware/migration'
require_relative 'auto_foreign_keys/middleware/schema'

module SchemaAutoForeignKeys
  module ActiveRecord
    module ConnectionAdapters
      autoload :Sqlite3Adapter, 'schema_plus/auto_foreign_keys/active_record/connection_adapters/sqlite3_adapter'
    end
  end
end

class SchemaPlus::ForeignKeys::Config
    ##
    # :attr_accessor: auto_create
    #
    # Whether to automatically create foreign key constraints for columns
    # suffixed with +_id+.  Boolean, default is +true+.
    has_value :auto_create, :klass => :boolean, :default => true

    ##
    # :attr_accessor: auto_index
    #
    # Whether to automatically create indexes when creating foreign key constraints for columns.
    # Boolean, default is +true+.
    has_value :auto_index, :klass => :boolean, :default => true
end

SchemaMonkey.register SchemaAutoForeignKeys
