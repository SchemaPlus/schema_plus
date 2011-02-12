module ActiveSchema::ActiveRecord::ConnectionAdapters
  module TableDefinition
    def self.included(base)
      base.class_eval do
        attr_accessor :name
        alias_method_chain :initialize, :active_schema
        alias_method_chain :column, :active_schema
        alias_method_chain :primary_key, :active_schema
        alias_method_chain :to_sql, :active_schema
      end
    end
        
    def initialize_with_active_schema(*args)
      initialize_without_active_schema(*args)
      @foreign_keys = []
    end

    def primary_key_with_active_schema(name, options = {})
      column(name, :primary_key, options)
    end

    def column_with_active_schema(name, type, options = {})
      column_without_active_schema(name, type, options)
      if references = ActiveRecord::Migration.get_references(self.name, name, options)
        ActiveSchema.set_default_update_and_delete_actions!(options)
        foreign_key(name, references.first, references.last, options) 
        if index = fk_index_options(options)
          # append [column_name, index_options] pair
          self.indexes << [name, ActiveSchema.options_for_index(index)]
        end
      elsif options[:index]
        self.indexes << [name, ActiveSchema.options_for_index(options[:index])]
      end
      self
    end

    def to_sql_with_active_schema
      sql = to_sql_without_active_schema
      sql << ', ' << @foreign_keys * ', ' unless @foreign_keys.empty?
      sql
    end

    def indexes
      @indexes ||= []
    end

    def foreign_key(column_names, references_table_name, references_column_names, options = {})
      @foreign_keys << ForeignKeyDefinition.new(options[:name], nil, column_names, ::ActiveRecord::Migrator.proper_table_name(references_table_name), references_column_names, options[:on_update], options[:on_delete], options[:deferrable])
      self
    end

    # Some people liked this; personally I've decided against using it but I'll keep it nonetheless
    def belongs_to(table, options = {})
      options = options.merge(:references => table)
      options[:on_delete] = options.delete(:dependent) if options.has_key?(:dependent)
      column("#{table.to_s.singularize}_id".to_sym, :integer, options)
    end

    protected
    def fk_index_options(options)
      options.fetch(:index,  fk_use_auto_index?)
    end

    def fk_use_auto_index?
      ActiveSchema.config.foreign_keys.auto_index && !ActiveRecord::Schema.defining?
    end

  end
end
