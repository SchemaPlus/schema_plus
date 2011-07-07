module SchemaPlus::ActiveRecord
  module Migration
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Overrides ActiveRecord#add_column and adds foreign key if column references other column
      #
      # add_column('comments', 'post_id', :integer)
      #   # creates a column and adds foreign key on posts(id)
      #
      # add_column('comments', 'post_id', :integer, :on_update => :cascade, :on_delete => :cascade)
      #   # creates a column and adds foreign key on posts(id) with cascade actions on update and on delete
      #
      # add_column('comments', 'post_id', :integer, :index => true)
      #   # creates a column and adds foreign key on posts(id)
      #   # additionally adds index on posts(id)
      #
      # add_column('comments', 'post_id', :integer, :index => { :unique => true, :name => 'comments_post_id_unique_index' }))
      #   # creates a column and adds foreign key on posts(id)
      #   # additionally adds unique index on posts(id) named comments_post_id_unique_index
      #
      # add_column('addresses', 'citizen_id', :integer, :references => :users
      #   # creates a column and adds foreign key on users(id)
      #
      # add_column('addresses', 'citizen_id', :integer, :references => [:users, :uuid]
      #   # creates a column and adds foreign key on users(uuid)
      #
      def add_column(table_name, column_name, type, options = {})
        super
        handle_column_options(table_name, column_name, options)
      end

      def change_column(table_name, column_name, type, options = {})
        super
        remove_foreign_key_if_exists(table_name, column_name)
        handle_column_options(table_name, column_name, options)
      end
      
      # Determines referenced table and column.
      # Used in migrations.  
      #
      # If auto_create is true:
      #   get_references('comments', 'post_id') # => ['posts', 'id']
      #
      # And if <tt>column_name</tt> is parent_id it references to the same table
      #   get_references('pages', 'parent_id')  # => ['pages', 'id']
      #
      # If :references option is given, it is used (whether or not auto_create is true)
      #   get_references('widgets', 'main_page_id', :references => 'pages')) 
      #   # => ['pages', 'id']
      #
      # Also the referenced id column may be specified:
      #   get_references('addresses', 'member_id', :references => ['users', 'uuid'])
      #   # => ['users', 'uuid']
      def get_references(table_name, column_name, options = {}, config=nil)
        column_name = column_name.to_s
        if options.has_key?(:references)
          references = options[:references]
          references = [references, :id] unless references.nil? || references.is_a?(Array)
          references
        elsif (config || SchemaPlus.config).foreign_keys.auto_create? && !ActiveRecord::Schema.defining?
          if column_name == 'parent_id'
            [table_name, :id]
          elsif column_name =~ /^(.*)_id$/
            determined_table_name = ActiveRecord::Base.pluralize_table_names ? $1.to_s.pluralize : $1
            [determined_table_name, :id]
          end
        end
      end

      protected
      def handle_column_options(table_name, column_name, options)
        if references = get_references(table_name, column_name, options)
          if index = options.fetch(:index, SchemaPlus.config.foreign_keys.auto_index? && !ActiveRecord::Schema.defining?)
            column_index(table_name, column_name, index)
          end
          add_foreign_key(table_name, column_name, references.first, references.last,
                          options.reverse_merge(:on_update => SchemaPlus.config.foreign_keys.on_update,
                                                :on_delete => SchemaPlus.config.foreign_keys.on_delete))
        elsif options[:index]
          column_index(table_name, column_name, options[:index])
        end
      end

      def column_index(table_name, column_name, options)
        options = {} if options == true
        column_name = [column_name] + Array.wrap(options.delete(:with)).compact
        add_index(table_name, column_name, options)
      end

      def remove_foreign_key_if_exists(table_name, column_name)
        foreign_keys = ActiveRecord::Base.connection.foreign_keys(table_name.to_s)
        fk = foreign_keys.detect { |fk| fk.table_name == table_name.to_s && fk.column_names == Array(column_name).collect(&:to_s) }
        remove_foreign_key(table_name, fk.name) if fk
      end

    end
  end
end
