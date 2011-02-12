module ActiveSchema
  module ActiveRecord
    module Schema
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def self.extended(base)
          class << base
            attr_accessor :defining
            alias :defining? :defining

            alias_method_chain :define, :active_schema
          end
        end

        def define_with_active_schema(info={}, &block)
          self.defining = true
          define_without_active_schema(info, &block)
        ensure
          self.defining = false
        end
      end
    end
  end
end
