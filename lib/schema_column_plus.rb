require 'schema_monkey'
require 'schema_plus_indexes'

require_relative 'schema_column_plus/active_record/connection_adapters/column'
require_relative 'schema_column_plus/middleware/model'

SchemaMonkey.register(SchemaColumnPlus)
