module RedHillConsulting::ForeignKeyMigrations::ActiveRecord
  module Migration
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def add_column(table_name, column_name, type, options = {})
        super
        references = ActiveRecord::Base.references(table_name, column_name, options)
        add_foreign_key(table_name, column_name, references.first, references.last, options) if references
      end
    end
  end
end
