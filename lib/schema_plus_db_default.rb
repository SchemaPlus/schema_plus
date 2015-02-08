require 'schema_monkey'

require_relative 'schema_plus_db_default/active_record/attribute'
require_relative 'schema_plus_db_default/db_default'
require_relative 'schema_plus_db_default/middleware'

module SchemaPlusDbDefault
  def self.insert(dbm: nil)
    ::ActiveRecord.const_set(:DB_DEFAULT, SchemaPlusDbDefault::DB_DEFAULT)
  end
end

SchemaMonkey.register(SchemaPlusDbDefault)
