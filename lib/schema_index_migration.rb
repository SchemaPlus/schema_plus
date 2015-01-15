require 'schema_monkey'

require_relative 'schema_index_migration/middleware'

SchemaMonkey.register(SchemaIndexMigration)
