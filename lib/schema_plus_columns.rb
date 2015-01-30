require 'schema_monkey'
require 'schema_plus_indexes'

require_relative 'schema_plus_columns/active_record/connection_adapters/column'
require_relative 'schema_plus_columns/middleware/model'

SchemaMonkey.register(SchemaPlusColumns)
