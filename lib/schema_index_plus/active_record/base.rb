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
        # (memoized result gets reset in Middleware::Model::ResetColumnInformation)
        def indexes
          @indexes ||= connection.indexes(table_name, "#{name} Indexes")
        end

      end
    end
  end
end

