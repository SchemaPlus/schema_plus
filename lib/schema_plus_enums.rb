require 'schema_monkey'

require_relative 'schema_plus_enums/active_record'
require_relative 'schema_plus_enums/middleware'

SchemaMonkey.register(SchemaPlusEnums)
