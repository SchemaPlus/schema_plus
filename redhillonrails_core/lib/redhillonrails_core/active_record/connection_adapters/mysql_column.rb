module RedhillonrailsCore
  module ActiveRecord
    module ConnectionAdapters
      module MysqlColumn
        def initialize(name, default, sql_type = nil, null = true)
          default = nil if !null && default.blank?
          super
        end
      end
    end
  end
end
