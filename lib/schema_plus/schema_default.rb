require_relative 'schema_monkey'

require_relative 'schema_default/active_record/attribute'
require_relative 'schema_default/db_default'
require_relative 'schema_default/postgresql_exec_cache'

module SchemaDefault
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter
        def self.included(base)
          SchemaMonkey::Middleware::ExecCache.insert(0, SchemaDefault::PostgreqlExecCache)
        end
      end
    end
  end

  def self.insert
    ::ActiveRecord.const_set(:DB_DEFAULT, SchemaDefault::DB_DEFAULT)
    ::ActiveRecord::Attribute.send(:include, SchemaDefault::ActiveRecord::Attribute)
  end
end

SchemaMonkey.register(SchemaDefault)
