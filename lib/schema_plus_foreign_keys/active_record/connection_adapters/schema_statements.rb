module SchemaPlusForeignKeys::ActiveRecord::ConnectionAdapters
  module SchemaStatements

    def self.included(base) #:nodoc:
      base.class_eval do
        alias_method_chain :create_table, :schema_plus_foreign_keys
      end
    end

    ##
    # :method: create_table
    #
    # SchemaPlusForeignKeys extends SchemaStatements::create_table to allow you to specify configuration options per table.  Pass them in as a hash keyed by configuration set (see SchemaPlusForeignKeys::Config),
    # for example:
    #
    #     create_table :widgets, :foreign_keys => {:auto_create => true, :on_delete => :cascade} do |t|
    #        ...
    #     end
    def create_table_with_schema_plus_foreign_keys(table, options = {})
      options = options.dup
      config_options = options.delete(:foreign_keys) || {}

      # override rails' :force to cascade
      drop_table(table, if_exists: true, cascade: true) if options.delete(:force)

      create_table_without_schema_plus_foreign_keys(table, options) do |table_definition|
        table_definition.schema_plus_config = SchemaPlusForeignKeys.config.merge(config_options)
        yield table_definition if block_given?
      end
    end
  end

end
