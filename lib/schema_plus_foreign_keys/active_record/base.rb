module SchemaPlusForeignKeys
  module ActiveRecord

    #
    # SchemaPlusForeignKeys adds several methods to ActiveRecord::Base
    #
    module Base
      module ClassMethods #:nodoc:

        public

        # Returns a list of ForeignKeyDefinition objects, for each foreign
        # key constraint defined in this model's table
        #
        # (memoized result gets reset in Middleware::Model::ResetColumnInformation)
        def foreign_keys
          @foreign_keys ||= connection.foreign_keys(table_name, "#{name} Foreign Keys")
        end

        def reset_foreign_key_information
          @foreign_keys = nil
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
