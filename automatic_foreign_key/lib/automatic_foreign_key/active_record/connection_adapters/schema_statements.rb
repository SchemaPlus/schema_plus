module AutomaticForeignKey::ActiveRecord::ConnectionAdapters
  module SchemaStatements

    def self.included(base)
      base.class_eval do
        alias_method_chain :create_table, :automatic_foreign_key
      end
    end

    def create_table_with_automatic_foreign_key(table, options = {})
      indices = nil
      create_table_without_automatic_foreign_key(table, options) do |table_definition|
        yield table_definition if block_given?
        indices = table_definition.indices
      end
      indices.each do |column_name, index_options|
        column_names = [column_name] + Array.wrap(index_options.delete(:with))
        add_index(table, column_names, index_options)
      end 
    end

  end
end
