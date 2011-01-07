module RedhillonrailsCore
  module ActiveRecord
    module ConnectionAdapters
      module TableDefinition
        def self.included(base)
          base.class_eval do
            attr_accessor :name
            alias_method_chain :initialize, :redhillonrails_core
            alias_method_chain :to_sql, :redhillonrails_core
          end
        end

        def initialize_with_redhillonrails_core(*args)
          initialize_without_redhillonrails_core(*args)
          @foreign_keys = []
        end

        def foreign_key(column_names, references_table_name, references_column_names, options = {})
          @foreign_keys << ForeignKeyDefinition.new(options[:name], nil, column_names, ::ActiveRecord::Migrator.proper_table_name(references_table_name), references_column_names, options[:on_update], options[:on_delete], options[:deferrable])
          self
        end

        def to_sql_with_redhillonrails_core
          sql = to_sql_without_redhillonrails_core
          sql << ', ' << @foreign_keys * ', ' unless @foreign_keys.empty? || ::ActiveRecord::Schema.defining?
          sql
        end
      end
    end
  end
end
