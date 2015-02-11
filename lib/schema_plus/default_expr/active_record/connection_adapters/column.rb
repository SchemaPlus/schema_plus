module SchemaPlusDefaultExpr
  module ActiveRecord
    module ConnectionAdapters
      module Column
        module Sqlite3
          def default_function
            @default_function ||= "(#{default})" if default =~ /DATETIME/
            super
          end
        end
      end
    end
  end
end
