require 'schema_plus/foreign_keys'

require_relative 'auto_foreign_keys/middleware/migration'

SchemaMonkey.register SchemaAutoForeignKeys
