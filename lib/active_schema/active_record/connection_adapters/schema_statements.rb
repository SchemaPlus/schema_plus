module ActiveSchema::ActiveRecord::ConnectionAdapters
  module SchemaStatements

    def self.included(base)
      base.class_eval do
        alias_method_chain :create_table, :active_schema
      end
    end

    def create_table_with_active_schema(table, options = {})
      indexes = nil
      create_table_without_active_schema(table, options) do |table_definition|
        yield table_definition if block_given?
        indexes = table_definition.indexes
      end
      indexes.each do |column_name, index_options|
        column_names = [column_name] + Array.wrap(index_options.delete(:with))
        add_index(table, column_names, index_options)
      end 
    end

  end
end
