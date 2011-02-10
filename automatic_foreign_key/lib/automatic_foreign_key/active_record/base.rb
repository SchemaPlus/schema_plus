module AutomaticForeignKey::ActiveRecord
  module Base
    def self.included(base) # :nodoc
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Determines referenced table and column.
      # Used in migrations.
      #   references('comments', 'post_id') # => ['posts', 'id']
      #
      # If <tt>column_name</tt> is parent_id it references to the same table
      #   references('pages', 'parent_id')  # => ['pages', 'id']
      #
      # If referenced table cannot be determined properly it may be overriden
      #   references('widgets', 'main_page_id', :references => 'pages')) 
      #   # => ['pages', 'id']
      #
      # Also whole result may be given by hand
      #   references('addresses', 'member_id', :references => ['users', 'uuid'])
      #   # => ['users', 'uuid']
      def references(table_name, column_name, options = {})
        column_name = column_name.to_s
        if options.has_key?(:references)
          references = options[:references]
          references = [references, :id] unless references.nil? || references.is_a?(Array)
          references
        elsif column_name == 'parent_id'
          [table_name, :id]
        elsif column_name =~ /^(.*)_id$/
          determined_table_name = ActiveRecord::Base.pluralize_table_names ? $1.to_s.pluralize : $1
          [determined_table_name, :id]
        end
      end
    end
  end
end
