module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module MysqlAdapter

        def self.included(base)
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements
        end

      end
    end
  end
end

