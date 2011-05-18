module ActiveSchema::ActiveRecord::ConnectionAdapters
  module TableDefinition

    attr_accessor :active_schema_config

    def self.included(base)
      base.class_eval do
        attr_accessor :name
        attr_accessor :indexes
        alias_method_chain :initialize, :active_schema
        alias_method_chain :column, :active_schema
        alias_method_chain :primary_key, :active_schema
        alias_method_chain :to_sql, :active_schema
      end
    end
        
    def initialize_with_active_schema(*args)
      initialize_without_active_schema(*args)
      @foreign_keys = []
      @indexes = []
    end

    def primary_key_with_active_schema(name, options = {})
      column(name, :primary_key, options)
    end

    def column_with_active_schema(name, type, options = {})
      column_without_active_schema(name, type, options)
      if references = ActiveRecord::Migration.get_references(self.name, name, options, active_schema_config)
        if index = options.fetch(:index, fk_use_auto_index?)
          self.column_index(name, index)
        end
        foreign_key(name, references.first, references.last,
                    options.reverse_merge(:on_update => active_schema_config.foreign_keys.on_update,
                                          :on_delete => active_schema_config.foreign_keys.on_delete))
      elsif options[:index]
        self.column_index(name, options[:index])
      end
      self
    end

    def to_sql_with_active_schema
      sql = to_sql_without_active_schema
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
      active_schema_config.foreign_keys.auto_index? && !ActiveRecord::Schema.defining?
    end

  end
end
