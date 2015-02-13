module SchemaPlus::Tables
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter

        # Extends rails' drop_table to include these options:
        #   :cascade
        #   :if_exists
        #
        def drop_table(name, options = {})
          sql = "DROP TABLE"
          sql += " IF EXISTS" if options[:if_exists]
          sql += " #{quote_table_name(name)}"
          sql += " CASCADE" if options[:cascade]
          execute sql
        end
      end
    end
  end
end
