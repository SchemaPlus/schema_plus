require 'schema_monkey'

require_relative 'schema_db_default/active_record/attribute'
require_relative 'schema_db_default/db_default'
require_relative 'schema_db_default/middleware'

module SchemaDbDefault

  def self.insert
    ::ActiveRecord.const_set(:DB_DEFAULT, SchemaDbDefault::DB_DEFAULT)
    ::ActiveRecord::Attribute.send(:include, SchemaDbDefault::ActiveRecord::Attribute)
  end
end

SchemaMonkey.register(SchemaDbDefault)
