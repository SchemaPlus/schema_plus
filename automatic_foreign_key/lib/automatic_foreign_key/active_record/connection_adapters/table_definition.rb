require 'active_support'
require 'active_support/core_ext/module/attr_accessor_with_default'

module AutomaticForeignKey::ActiveRecord::ConnectionAdapters
  module TableDefinition
    def self.included(base)
      base.class_eval do
        alias_method_chain :column, :automatic_foreign_key
        alias_method_chain :primary_key, :automatic_foreign_key
      end
    end
        
    def primary_key_with_automatic_foreign_key(name, options = {})
      column(name, :primary_key, options)
    end

    def indices
      @indices ||= []
    end

    def column_with_automatic_foreign_key(name, type, options = {})
      column_without_automatic_foreign_key(name, type, options)
      references = ActiveRecord::Base.references(self.name, name, options)
      if references
        AutomaticForeignKey.set_default_update_and_delete_actions!(options)
        foreign_key(name, references.first, references.last, options) 
        if index = afk_index_options(options)
          # append [column_name, index_options] pair
          self.indices << [name, AutomaticForeignKey.options_for_index(index)]
        end
      elsif options[:index]
        self.indices << [name, AutomaticForeignKey.options_for_index(options[:index])]
      end
      self
    end

    # Some people liked this; personally I've decided against using it but I'll keep it nonetheless
    def belongs_to(table, options = {})
      options = options.merge(:references => table)
      options[:on_delete] = options.delete(:dependent) if options.has_key?(:dependent)
      column("#{table.to_s.singularize}_id".to_sym, :integer, options)
    end

    protected
    def afk_index_options(options)
      options.fetch(:index,  afk_use_auto_index?)
    end

    def afk_use_auto_index?
      AutomaticForeignKey.auto_index && !ActiveRecord::Schema.defining?
    end

  end
end
