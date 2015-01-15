require 'schema_monkey'

require_relative 'schema_pg_enums/active_record'
require_relative 'schema_pg_enums/middleware'

SchemaMonkey.register(SchemaPgEnums)
