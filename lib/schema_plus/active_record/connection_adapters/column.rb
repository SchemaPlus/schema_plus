module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters

      #
      # SchemaPlus adds several methods to Column
      #
      module Column


        # Returns the circumstance in which the column must have a value:
        #   nil     if the column may be null
        #   :save   if the column has no default value
        #   :update otherwise
        def required_on
          if null
            nil
          elsif default.nil?
            :save
          else
            :update
          end
        end

      end
    end
  end
end
