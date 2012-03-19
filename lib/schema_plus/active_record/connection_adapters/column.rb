module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters

      #
      # SchemaPlus adds several methods to Column
      #
      module Column

        attr_reader :default_expr
        attr_writer :connection # connection gets set by SchemaPlus::ActiveRecord::Base::columns_with_schema_plus

        # Returns the list of IndexDefinition instances for each index that
        # refers to this column.  Returns an empty list if there are no
        # such indexes.
        def indexes
          @indexes ||= @connection.indexes.select{|index| index.columns.include? self.name}
        end

        # If the column is in a unique index, returns a list of names of other columns in
        # the index.  Returns an empty list if it's a single-column index.
        # Returns nil if the column is not in a unique index.
        def unique_scope
          if index = indexes.select{|i| i.unique}.sort_by{|i| i.columns.size}.first
            index.columns.reject{|name| name == self.name}
          end
        end

        # Returns true if the column is in a unique index.  See also
        # unique_scope
        def unique?
          indexes.any?{|i| i.unique}
        end

        # Returns true if the column is in one or more indexes that are
        # case sensitive
        def case_sensitive?
          indexes.any?{|i| i.case_sensitive?}
        end

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
