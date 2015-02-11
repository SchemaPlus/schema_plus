module SchemaPlus::ForeignKeys
  module ActiveRecord
    module Schema
      module ClassMethods

        def define(*args)
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
