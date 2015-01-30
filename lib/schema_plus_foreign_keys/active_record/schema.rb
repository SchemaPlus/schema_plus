module SchemaPlusForeignKeys
  module ActiveRecord
    module Schema #:nodoc: all
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def self.extended(base)
          class << base
            alias_method_chain :define, :schema_plus_foreign_keys
          end
        end

        def define_with_schema_plus_foreign_keys(info={}, &block)
          fk_override = { :auto_create => false, :auto_index => false }
          save = Hash[fk_override.keys.collect{|key| [key, SchemaPlusForeignKeys.config.send(key)]}]
          begin
            SchemaPlusForeignKeys.config.update_attributes(fk_override)
            define_without_schema_plus_foreign_keys(info, &block)
          ensure
            SchemaPlusForeignKeys.config.update_attributes(save)
          end
        end
      end
    end
  end
end
