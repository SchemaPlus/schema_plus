module SchemaAutoForeignKeys
  module Middleware
    module Schema
      module Define
        def around(env)
          fk_override = { :auto_create => false, :auto_index => false }
          save = Hash[fk_override.keys.collect{|key| [key, SchemaPlus::ForeignKeys.config.send(key)]}]
          begin
            SchemaPlus::ForeignKeys.config.update_attributes(fk_override)
            yield env
          ensure
            SchemaPlus::ForeignKeys.config.update_attributes(save)
          end
        end
      end
    end
  end
end
