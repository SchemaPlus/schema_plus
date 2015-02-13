module SchemaPlus::Tables
  module ActiveRecord
    module ConnectionAdapters
      module Mysql2Adapter

        # implement cascade by removing foreign keys
        def drop_table(name, options={})
          if options[:cascade]
            reverse_foreign_keys(name).each do |foreign_key|
              remove_foreign_key(foreign_key.from_table, name: foreign_key.name)
            end
          end

          sql = 'DROP'
          sql += ' TEMPORARY' if options[:temporary]
          sql += ' TABLE'
          sql += ' IF EXISTS' if options[:if_exists]
          sql += " #{quote_table_name(name)}"

          execute sql
        end
      end
    end
  end
end
