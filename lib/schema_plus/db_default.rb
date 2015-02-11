require 'schema_plus/core'

require_relative 'db_default/active_record/attribute'
require_relative 'db_default/db_default'
require_relative 'db_default/middleware'

SchemaMonkey.register SchemaPlusDbDefault
