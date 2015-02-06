module SchemaPlusForeignKeys
  module ActiveRecord
    module Schema #:nodoc: all
      def self.prepended(base)
        base.singleton_class.prepend ClassMethods
      end

      module ClassMethods

        def define(*args)
          fk_override = { :auto_create => false, :auto_index => false }
          save = Hash[fk_override.keys.collect{|key| [key, SchemaPlusForeignKeys.config.send(key)]}]
          begin
            SchemaPlusForeignKeys.config.update_attributes(fk_override)
            super
          ensure
            SchemaPlusForeignKeys.config.update_attributes(save)
          end
        end
      end
    end
  end
end
