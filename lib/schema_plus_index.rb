require 'schema_monkey'

require_relative 'schema_plus_index/active_record/base'
require_relative 'schema_plus_index/active_record/connection_adapters/abstract_adapter'
require_relative 'schema_plus_index/active_record/connection_adapters/index_definition'
require_relative 'schema_plus_index/middleware/dumper'
require_relative 'schema_plus_index/middleware/migration'
require_relative 'schema_plus_index/middleware/model'
require_relative 'schema_plus_index/middleware/postgresql'
require_relative 'schema_plus_index/middleware/sqlite3'

SchemaMonkey.register(SchemaPlusIndex)
