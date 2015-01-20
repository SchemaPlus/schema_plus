module SchemaIndexPlus
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter

        def self.included(base) #:nodoc:
          base.alias_method_chain :remove_index, :schema_plus
        end

        # Extends rails' remove_index to include this options:
        #   :if_exists
        def remove_index_with_schema_plus(table_name, *args)
          options = args.extract_options!
          if_exists = options.delete(:if_exists)
          args << options if options.any?
          return if if_exists and not index_name_exists?(table_name, options[:name] || index_name(table_name, *args), false)
          remove_index_without_schema_plus(table_name, *args)
        end

      end
    end
  end
end
