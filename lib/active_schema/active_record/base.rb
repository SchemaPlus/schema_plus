module ActiveSchema
  module ActiveRecord
    module Base
      def self.included(base)
        base.extend(ClassMethods)
        base.extend(ActiveSchema::ActiveRecord::Associations)
      end

      module ClassMethods
        def self.extended(base)
          class << base
            alias_method_chain :columns, :active_schema
            alias_method_chain :abstract_class?, :active_schema
            alias_method_chain :reset_column_information, :active_schema

            alias_method_chain :allocate, :active_schema
            alias_method_chain :new, :active_schema
            alias_method_chain :reflections, :active_schema
          end
        end

        def inherited(child)
          active_schema_extensions if self != ::ActiveRecord::Base
          super
        end

        def allocate_with_active_schema
          active_schema_extensions
          allocate_without_active_schema
        end

        def new_with_active_schema(*args)
          active_schema_extensions
          new_without_active_schema(*args) { |*block_args| yield(*block_args) if block_given? }
        end

        def reflections_with_active_schema
          active_schema_extensions
          reflections_without_active_schema
        end

        private

        def active_schema_extensions
          # Don't bother if: already extended; or the class is abstract; not a base class; or the table doesn't exist
          return if @active_schema_extended || abstract_class? || !base_class? || !table_exists?

          @active_schema_extended = true
          load_active_schema_associations if active_schema_config.associations.auto_create?
        end

        public

        # class decorator
        def active_schema(opts)
          @active_schema_config = ActiveSchema.config.merge(opts)
        end

        def base_class?
          self == base_class
        end

        def abstract_class_with_active_schema?
          abstract_class_without_active_schema? || !(name =~ /^Abstract/).nil?
        end

        def columns_with_active_schema
          unless @columns
            columns_without_active_schema
            cols = columns_hash
            indexes.each do |index|
              next if index.columns.blank?
              column_name = index.columns.reverse.detect { |name| name !~ /_id$/ } || index.columns.last
              column = cols[column_name]
              column.case_sensitive = index.case_sensitive?
              column.unique_scope = index.columns.reject { |name| name == column_name } if index.unique
            end
          end
          @columns
        end

        def reset_column_information_with_active_schema
          reset_column_information_without_active_schema
          @indexes = @foreign_keys = nil
        end

        def pluralized_table_name(table_name)
          ::ActiveRecord::Base.pluralize_table_names ? table_name.to_s.pluralize : table_name
        end

        def indexes
          @indexes ||= connection.indexes(table_name, "#{name} Indexes")
        end

        def foreign_keys
          @foreign_keys ||= connection.foreign_keys(table_name, "#{name} Foreign Keys")
        end

        def reverse_foreign_keys
          connection.reverse_foreign_keys(table_name, "#{name} Reverse Foreign Keys")
        end

        def active_schema_config
          @active_schema_config ||= ActiveSchema.config.dup
        end
      end
    end
  end
end
