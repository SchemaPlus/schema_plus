module RedhillonrailsCore
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

            alias_method_chain :define, :redhillonrails_core
          end
        end

        def define_with_redhillonrails_core(info={}, &block)
          self.defining = true
          define_without_redhillonrails_core(info, &block)
        ensure
          self.defining = false
        end
      end
    end
  end
end
