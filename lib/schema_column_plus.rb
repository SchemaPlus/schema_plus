require 'schema_monkey'
require 'schema_index_plus'

require_relative 'schema_column_plus/active_record/connection_adapters/column'
require_relative 'schema_column_plus/middleware/model'

SchemaMonkey.register(SchemaColumnPlus)
