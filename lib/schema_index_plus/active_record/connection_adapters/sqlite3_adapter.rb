module SchemaIndexPlus
  module ActiveRecord
    module ConnectionAdapters
      module Sqlite3Adapter

        def self.included(base)
          base.class_eval do
            alias_method_chain :indexes, :schema_plus
          end
        end

        def indexes_with_schema_plus(table_name, name = nil)
          indexes = indexes_without_schema_plus(table_name, name)
          exec_query("SELECT name, sql FROM sqlite_master WHERE type = 'index'").map do |row|
            sql = row['sql']
            index = nil
            getindex = -> { index ||= indexes.detect { |i| i.name == row['name'] } }
            if (desc_columns = sql.scan(/['"`]?(\w+)['"`]? DESC\b/).flatten).any?
              getindex.call()
              index.orders = Hash[index.columns.map {|column| [column, desc_columns.include?(column) ? :desc : :asc]}]
            end
          end
          indexes
        end
      end
    end
  end
end
