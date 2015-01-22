module SchemaPlusTables
  module ActiveRecord
    module ConnectionAdapters
      module Sqlite3Adapter

        def drop_table(name, options={})
          super(name, options.except(:cascade))
        end
      end
    end
  end
end
