require 'schema_monkey'

require_relative 'schema_default_expr/active_record'
require_relative 'schema_default_expr/middleware'

SchemaMonkey.register(SchemaDefaultExpr)
