module SchemaAutoForeignKeys
  module ActiveRecord
    module ConnectionAdapters

      # SchemaPlus::ForeignKeys includes an Sqlite3 implementation of the AbstractAdapter
      # extensions.
      module Sqlite3Adapter

        def copy_table(*args, &block)
          fk_override = { :auto_create => false, :auto_index => false }
          save = Hash[fk_override.keys.collect{|key| [key, SchemaPlus::ForeignKeys.config.send(key)]}]
          begin
            SchemaPlus::ForeignKeys.config.update_attributes(fk_override)
            super
          ensure
            SchemaPlus::ForeignKeys.config.update_attributes(save)
          end
        end
      end
    end
  end
end
