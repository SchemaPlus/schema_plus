require 'schema_monkey_rails'
require 'schema_plus/columns'
require 'schema_plus/db_default'
require 'schema_plus/default_expr'
require 'schema_plus/enums'
require 'schema_plus/foreign_keys'
require 'schema_plus_indexes'
require 'schema_plus_pg_indexes'
require 'schema_plus/tables'
require 'schema_plus/views'

require_relative 'schema_plus/version'

module SchemaPlus
  class DeprecatedConfig
    def foreign_keys
      SchemaPlusForeignKeys.config
    end
  end

  def self.setup # :yields: config
    ActiveSupport::Deprecation.warning "SchemaPlus.setup is deprecated.  Use SchemaPlusForeignKeys.setup instead"
    yield DeprecatedConfig.new
  end
end
