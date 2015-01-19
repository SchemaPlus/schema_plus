module SchemaIndexPlus
  module ActiveRecord

    module Base
      def self.included(base) #:nodoc:
        base.extend(ClassMethods)
      end

      module ClassMethods #:nodoc:

        public

        # Returns a list of IndexDefinition objects, for each index
        # defind on this model's table.
        #
        def indexes
          @indexes ||= connection.indexes(table_name, "#{name} Indexes")
        end

        # (reset_index_information gets called by by Middleware::Model::ResetColumnInformation)
        def reset_index_information
          @indexes = nil
        end

      end
    end
  end
end

