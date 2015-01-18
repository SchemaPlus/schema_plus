require 'schema_monkey'

require_relative 'schema_index_plus/active_record/base'
require_relative 'schema_index_plus/active_record/connection_adapters/abstract_adapter'
require_relative 'schema_index_plus/active_record/connection_adapters/column'
require_relative 'schema_index_plus/active_record/connection_adapters/index_definition'
require_relative 'schema_index_plus/middleware/dumper'
require_relative 'schema_index_plus/middleware/migration'
require_relative 'schema_index_plus/middleware/postgresql'
require_relative 'schema_index_plus/middleware/sqlite3'

SchemaMonkey.register(SchemaIndexPlus)
