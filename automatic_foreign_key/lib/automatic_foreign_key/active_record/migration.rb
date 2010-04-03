module AutomaticForeignKey::ActiveRecord
  module Migration
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Overrides standard ActiveRecord add column and adds 
      # foreign key if column references other column
      #
      # add_column('comments', 'post_id', :integer)
      #   # creates a column and adds foreign key on posts(id)
      #
      # add_column('addresses', 'citizen_id', :integer, :references => :users
      #   # creates a column and adds foreign key on users(id)
      #
      # add_column('addresses', 'citizen_id', :integer, :references => [:users, :uuid]
      #   # creates a column and adds foreign key on users(uuid)
      #
      # add_column('users', 'verified')
      #   # just creates a column as usually
      def add_column(table_name, column_name, type, options = {})
        super
        references = ActiveRecord::Base.references(table_name, column_name, options)
        add_foreign_key(table_name, column_name, references.first, references.last, options) if references
      end
    end
  end
end
