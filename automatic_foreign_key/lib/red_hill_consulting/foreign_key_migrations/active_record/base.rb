module RedHillConsulting::ForeignKeyMigrations::ActiveRecord
  module Base
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def references(table_name, column_name, options = {})
        column_name = column_name.to_s
        if options.has_key?(:references)
          references = options[:references]
          references = [references, :id] unless references.nil? || references.is_a?(Array)
          references
        elsif column_name == 'parent_id'
          [table_name, :id]
        elsif column_name =~ /^(.*)_id$/
          [pluralized_table_name($1), :id]
        end
      end
    end
  end
end
