module SchemaPlus::ActiveRecord::ConnectionAdapters
  module SchemaStatements

    def self.included(base)
      base.class_eval do
        alias_method_chain :create_table, :schema_plus
      end
    end

    def create_table_with_schema_plus(table, options = {})
      options = options.dup
      config_options = {}
      options.keys.each { |key| config_options[key] = options.delete(key) if SchemaPlus.config.class.attributes.include? key }

      indexes = []
      create_table_without_schema_plus(table, options) do |table_definition|
        table_definition.schema_plus_config = SchemaPlus.config.merge(config_options)
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
