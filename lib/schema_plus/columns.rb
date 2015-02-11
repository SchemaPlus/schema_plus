require 'schema_plus_indexes'

require_relative 'columns/active_record/connection_adapters/column'
require_relative 'columns/middleware/model'

SchemaMonkey.register SchemaPlus::Columns
