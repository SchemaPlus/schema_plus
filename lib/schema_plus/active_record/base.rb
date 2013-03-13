module SchemaPlus
  module ActiveRecord

    #
    # SchemaPlus adds several methods to ActiveRecord::Base
    #
    module Base
      def self.included(base) #:nodoc:
        base.extend(ClassMethods)
      end

      module ClassMethods #:nodoc:
        def self.extended(base) #:nodoc:
          class << base
            alias_method_chain :columns, :schema_plus
            alias_method_chain :reset_column_information, :schema_plus
          end
        end

        public

        def columns_with_schema_plus #:nodoc:
          columns = columns_without_schema_plus
          columns.each do |column| column.model = self end unless @schema_plus_extended_columns
          columns
        end

        def reset_column_information_with_schema_plus #:nodoc:
          reset_column_information_without_schema_plus
          @indexes = @foreign_keys = @schema_plus_extended_columns = nil
        end

        # Returns a list of IndexDefinition objects, for each index
        # defind on this model's table.
        def indexes
          @indexes ||= connection.indexes(table_name, "#{name} Indexes")
        end

        # Returns a list of ForeignKeyDefinition objects, for each foreign
        # key constraint defined in this model's table
        def foreign_keys
          @foreign_keys ||= connection.foreign_keys(table_name, "#{name} Foreign Keys")
        end

        # Returns a list of ForeignKeyDefinition objects, for each foreign
        # key constraint of other tables that refer to this model's table
        def reverse_foreign_keys
          connection.reverse_foreign_keys(table_name, "#{name} Reverse Foreign Keys")
        end

      end
    end
  end
end
