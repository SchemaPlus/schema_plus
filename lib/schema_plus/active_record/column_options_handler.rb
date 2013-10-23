module SchemaPlus::ActiveRecord
  module ColumnOptionsHandler
    def schema_plus_handle_column_options(table_name, column_name, column_options, opts = {}) #:nodoc:
      config = opts[:config] || SchemaPlus.config
      fk_args = get_fk_args(table_name, column_name, column_options, config)

      # remove existing fk and auto-generated index in case of change to existing column
      if fk_args # includes :none for explicitly off
        remove_foreign_key_if_exists(table_name, column_name)
        remove_auto_index_if_exists(table_name, column_name)
      end

      fk_args = nil if fk_args == :none

      # create index if requested explicity or implicitly due to auto_index
      index = column_options[:index]
      if index.nil? and fk_args && config.foreign_keys.auto_index?
        index = { :name => auto_index_name(table_name, column_name) }
      end
      column_index(table_name, column_name, index) if index

      if fk_args
        references = fk_args.delete(:references)
        add_foreign_key(table_name, column_name, references.first, references.last, fk_args)
      end
    end

    protected

    def get_fk_args(table_name, column_name, column_options = {}, config = {}) #:nodoc:

      args = nil
      column_name = column_name.to_s

      if column_options.has_key?(:foreign_key)
        args = column_options[:foreign_key]
        return :none unless args
        args = {} if args == true
        return :none if args.has_key?(:references) and not args[:references]
      end


      if column_options.has_key?(:references)
        references = column_options[:references]
        return :none unless references
        args = (args || {}).reverse_merge(:references => references)
      end

      args ||= {} if config.foreign_keys.auto_create? and column_name =~ /_id$/

      return nil if args.nil?

      args[:references] ||= table_name if column_name == 'parent_id'

      args[:references] ||= begin
                              table_name = column_name.sub(/_id$/, '')
                              table_name = table_name.pluralize if ActiveRecord::Base.pluralize_table_names
                              table_name
                            end

      args[:references] = [args[:references], :id] unless args[:references].is_a? Array

      [:on_update, :on_delete, :deferrable].each do |shortcut|
        args[shortcut] ||= column_options[shortcut] if column_options.has_key? shortcut
      end

      args[:on_update] ||= config.foreign_keys.on_update
      args[:on_delete] ||= config.foreign_keys.on_delete

      args
    end

    def remove_foreign_key_if_exists(table_name, column_name) #:nodoc:
      foreign_keys = ActiveRecord::Base.connection.foreign_keys(table_name.to_s) rescue [] # no fks if table_name doesn't exist
      fk = foreign_keys.detect { |fk| fk.table_name == table_name.to_s && fk.column_names == Array(column_name).collect(&:to_s) }
      remove_foreign_key(table_name, fk.column_names, fk.references_table_name, fk.references_column_names) if fk
    end


    def column_index(table_name, column_name, options) #:nodoc:
      options = {} if options == true
      options = { :unique => true } if options == :unique
      column_name = [column_name] + Array.wrap(options.delete(:with)).compact
      add_index(table_name, column_name, options)
    end

    def remove_auto_index_if_exists(table_name, column_name)
      name = auto_index_name(table_name, column_name)
      remove_index(table_name, :name => name, :column => column_name, :if_exists => true)
    end

    def auto_index_name(table_name, column_name)
      ConnectionAdapters::ForeignKeyDefinition.auto_index_name(table_name, column_name)
    end

  end
end
