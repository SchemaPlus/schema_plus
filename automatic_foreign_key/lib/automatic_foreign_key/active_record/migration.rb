module AutomaticForeignKey::ActiveRecord
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

      protected
      def handle_column_options(table_name, column_name, options)
        references = ActiveRecord::Base.references(table_name, column_name, options)
        if references
          AutomaticForeignKey.set_default_update_and_delete_actions!(options)
          add_foreign_key(table_name, column_name, references.first, references.last, options) 
          if index = options.fetch(:index, AutomaticForeignKey.auto_index)
            add_index(table_name, column_name, AutomaticForeignKey.options_for_index(index))
          end
        elsif options[:index]
          add_index(table_name, column_name, AutomaticForeignKey.options_for_index(options[:index]))
        end
      end

      def remove_foreign_key_if_exists(table_name, column_name)
        foreign_keys = ActiveRecord::Base.connection.foreign_keys(table_name.to_s)
        fk = foreign_keys.detect { |fk| fk.table_name == table_name.to_s && fk.column_names == Array(column_name).collect(&:to_s) }
        remove_foreign_key(table_name, fk.name) if fk
      end

    end
  end
end
