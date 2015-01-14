require_relative 'schema_monkey'

require_relative 'schema_db_default/active_record/attribute'
require_relative 'schema_db_default/db_default'

module SchemaDbDefault

  autoload :PostgreqlExecCache, 'schema_plus/schema_db_default/postgresql_exec_cache'

  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter
        def self.included(base)
          SchemaMonkey::Middleware::ExecCache.insert(0, SchemaDbDefault::PostgreqlExecCache)
        end
      end
    end
  end

  def self.insert
    ::ActiveRecord.const_set(:DB_DEFAULT, SchemaDbDefault::DB_DEFAULT)
    ::ActiveRecord::Attribute.send(:include, SchemaDbDefault::ActiveRecord::Attribute)
  end
end

SchemaMonkey.register(SchemaDbDefault)
