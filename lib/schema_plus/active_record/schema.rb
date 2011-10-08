module SchemaPlus
  module ActiveRecord
    module Schema #:nodoc: all
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def self.extended(base)
          class << base
            alias_method_chain :define, :schema_plus
          end
        end

        def define_with_schema_plus(info={}, &block)
          fk_override = { :auto_create => false, :auto_index => false }
          save = Hash[fk_override.keys.collect{|key| [key, SchemaPlus.config.foreign_keys.send(key)]}]
          begin
            SchemaPlus.config.foreign_keys.update_attributes(fk_override)
            define_without_schema_plus(info, &block)
          ensure
            SchemaPlus.config.foreign_keys.update_attributes(save)
          end
        end
      end
    end
  end
end
