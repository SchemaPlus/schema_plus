module ActiveSchema::ActiveRecord::ConnectionAdapters
  module SchemaStatements

    def self.included(base)
      base.class_eval do
        alias_method_chain :create_table, :active_schema
      end
    end

    def create_table_with_active_schema(table, options = {})
      config_options = {}
      options.keys.each { |key| config_options[key] = options.delete(key) if ActiveSchema.config.respond_to? key }

      indexes = nil
      create_table_without_active_schema(table, options) do |table_definition|
        table_definition.active_schema_config = ActiveSchema.config.merge(config_options)
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
