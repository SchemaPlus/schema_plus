module SchemaPlus::ActiveRecord::ConnectionAdapters
  module TableDefinition

    attr_accessor :schema_plus_config

    def self.included(base)
      base.class_eval do
        attr_accessor :name
        attr_accessor :indexes
        alias_method_chain :initialize, :schema_plus
        alias_method_chain :column, :schema_plus
        alias_method_chain :primary_key, :schema_plus
        alias_method_chain :to_sql, :schema_plus
      end
    end
        
    def initialize_with_schema_plus(*args)
      initialize_without_schema_plus(*args)
      @foreign_keys = []
      @indexes = []
    end

    def primary_key_with_schema_plus(name, options = {})
      column(name, :primary_key, options)
    end

    def column_with_schema_plus(name, type, options = {})
      column_without_schema_plus(name, type, options)
      if references = ActiveRecord::Migration.get_references(self.name, name, options, schema_plus_config)
        if index = options.fetch(:index, fk_use_auto_index?)
          self.column_index(name, index)
        end
        foreign_key(name, references.first, references.last,
                    options.reverse_merge(:on_update => schema_plus_config.foreign_keys.on_update,
                                          :on_delete => schema_plus_config.foreign_keys.on_delete))
      elsif options[:index]
        self.column_index(name, options[:index])
      end
      self
    end

    def to_sql_with_schema_plus
      sql = to_sql_without_schema_plus
      sql << ', ' << @foreign_keys * ', ' unless @foreign_keys.empty?
      sql
    end

    def index(column_name, options={})
      @indexes << ::ActiveRecord::ConnectionAdapters::IndexDefinition.new(self.name, column_name, options)
    end

    def foreign_key(column_names, references_table_name, references_column_names, options = {})
      @foreign_keys << ForeignKeyDefinition.new(options[:name], nil, column_names, ::ActiveRecord::Migrator.proper_table_name(references_table_name), references_column_names, options[:on_update], options[:on_delete], options[:deferrable])
      self
    end

    protected
    def column_index(name, options)
      options = {} if options == true
      name = [name] + Array.wrap(options.delete(:with)).compact
      self.index(name, options)
    end

    def fk_use_auto_index?
      schema_plus_config.foreign_keys.auto_index? && !ActiveRecord::Schema.defining?
    end

  end
end
