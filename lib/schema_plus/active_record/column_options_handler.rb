module SchemaPlus::ActiveRecord
  module ColumnOptionsHandler
    def schema_plus_handle_column_options(table_name, column_name, column_options, opts = {}) #:nodoc:
      config = opts[:config] || SchemaPlus.config
      if references = get_references(table_name, column_name, column_options, config)
        if index = column_options.fetch(:index, config.foreign_keys.auto_index? && !ActiveRecord::Schema.defining?)
          column_index(table_name, column_name, index)
        end
        add_foreign_key(table_name, column_name, references.first, references.last,
                                    column_options.reverse_merge(:on_update => config.foreign_keys.on_update,
                                                                 :on_delete => config.foreign_keys.on_delete))
      elsif column_options[:index]
        column_index(table_name, column_name, column_options[:index])
      end
    end

    protected

    # If auto_create is true:
    #   get_references('comments', 'post_id') # => ['posts', 'id']
    #
    # And if <tt>column_name</tt> is parent_id it references to the same table
    #   get_references('pages', 'parent_id')  # => ['pages', 'id']
    #
    # If :references option is given, it is used (whether or not auto_create is true)
    #   get_references('widgets', 'main_page_id', :references => 'pages')) => ['pages', 'id']
    #
    # Also the referenced id column may be specified:
    #   get_references('addresses', 'member_id', :references => ['users', 'uuid']) => ['users', 'uuid']
    #
    def get_references(table_name, column_name, column_options = {}, config) #:nodoc:
      if column_options.has_key?(:references)
        references = column_options[:references]
        references = [references, :id] unless references.nil? || references.is_a?(Array)
        references
      elsif config.foreign_keys.auto_create? && !ActiveRecord::Schema.defining?
        case column_name.to_s
        when 'parent_id'
          [table_name, :id]
        when /^(.*)_id$/
          determined_table_name = ActiveRecord::Base.pluralize_table_names ? $1.to_s.pluralize : $1
          [determined_table_name, :id]
        end
      end
    end

    def column_index(table_name, column_name, options) #:nodoc:
      options = {} if options == true
      options = { :unique => true } if options == :unique
      column_name = [column_name] + Array.wrap(options.delete(:with)).compact
      add_index(table_name, column_name, options)
    end

  end
end
