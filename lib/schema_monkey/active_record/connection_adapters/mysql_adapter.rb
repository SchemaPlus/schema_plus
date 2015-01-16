module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module MysqlAdapter

        def self.included(base)
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Column
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Reference
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Index
        end
      end
    end
  end
end

