module ActiveSchema::ActiveRecord::ConnectionAdapters
  module SchemaStatements

    def self.included(base)
      base.class_eval do
        alias_method_chain :create_table, :active_schema
      end
    end

    def create_table_with_active_schema(table, options = {})
      options = options.dup
      config_options = {}
      options.keys.each { |key| config_options[key] = options.delete(key) if ActiveSchema.config.class.attributes.include? key }

      indexes = []
      create_table_without_active_schema(table, options) do |table_definition|
        table_definition.active_schema_config = ActiveSchema.config.merge(config_options)
        table_definition.name = table
        yield table_definition if block_given?
        indexes = table_definition.indexes
      end
      indexes.each do |index|
        add_index(table, index.columns, index.opts)
      end


    end

  end
end
