require 'schema_pg_enums'
require 'schema_plus_columns'
require 'schema_plus_db_default'
require 'schema_plus_default_expr'
require 'schema_plus_foreign_keys'
require 'schema_plus_indexes'
require 'schema_plus_pg_indexes'
require 'schema_plus_tables'
require 'schema_plus_views'

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
