module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module Sqlite3Adapter

        def self.included(base)
          SchemaMonkey.patch ::ActiveRecord::ConnectionAdapters::SchemaStatements
        end

      end
    end
  end
end


