module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module Sqlite3Adapter

        def self.included(base)
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::SchemaStatements, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Column
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::SchemaStatements, SchemaMonkey::ActiveRecord::ConnectionAdapters::SchemaStatements::Reference
        end

      end
    end
  end
end


