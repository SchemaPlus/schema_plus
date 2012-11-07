module SchemaPlus::ActiveRecord
  module ColumnOptionsHandler
    def schema_plus_handle_column_options(table_name, column_name, column_options, opts = {}) #:nodoc:
      config = opts[:config] || SchemaPlus.config
      if fk_args = get_fk_args(table_name, column_name, column_options, config)

        # in case of change to existing column
        remove_foreign_key_if_exists(table_name, column_name)

        unless fk_args == :none
          if index = column_options.fetch(:index, config.foreign_keys.auto_index?)
            column_index(table_name, column_name, index)
          end

          references = fk_args.delete(:references)
          add_foreign_key(table_name, column_name, references.first, references.last, fk_args)
        end
      elsif column_options[:index]
        column_index(table_name, column_name, column_options[:index])
      end
    end

    protected

    def get_fk_args(table_name, column_name, column_options = {}, config = {}) #:nodoc:

      args = nil

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

      args[:references] ||= case column_name.to_s
                            when 'parent_id'
                              [table_name, :id]
                            when /^(.*)_id$/
                              references_table_name = ActiveRecord::Base.pluralize_table_names ? $1.to_s.pluralize : $1
                              [references_table_name, :id]
                            else
                              references_table_name = ActiveRecord::Base.pluralize_table_names ? column_name.to_s.pluralize : column_name
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
      remove_foreign_key(table_name, fk.name) if fk
    end


    def column_index(table_name, column_name, options) #:nodoc:
      options = {} if options == true
      options = { :unique => true } if options == :unique
      column_name = [column_name] + Array.wrap(options.delete(:with)).compact
      add_index(table_name, column_name, options)
    end

  end
end
