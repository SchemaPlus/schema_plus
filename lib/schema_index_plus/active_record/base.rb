module SchemaIndexPlus
  module ActiveRecord

    module Base
      def self.included(base) #:nodoc:
        base.extend(ClassMethods)
      end

      module ClassMethods #:nodoc:
        def self.extended(base) #:nodoc:
          class << base
            alias_method_chain :reset_column_information, :schema_index_plus
          end
        end

        public

        def reset_column_information_with_schema_index_plus #:nodoc:
          reset_column_information_without_schema_index_plus
          @indexes = nil
        end

        # Returns a list of IndexDefinition objects, for each index
        # defind on this model's table.
        def indexes
          @indexes ||= connection.indexes(table_name, "#{name} Indexes")
        end

      end
    end
  end
end

