module SchemaPlus
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

            alias_method_chain :define, :schema_plus
          end
        end

        def define_with_schema_plus(info={}, &block)
          self.defining = true
          define_without_schema_plus(info, &block)
        ensure
          self.defining = false
        end
      end
    end
  end
end
