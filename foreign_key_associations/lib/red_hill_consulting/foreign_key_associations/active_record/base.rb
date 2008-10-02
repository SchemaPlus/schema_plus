module RedHillConsulting::ForeignKeyAssociations::ActiveRecord
  module Base
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def self.extended(base)
        class << base
          alias_method_chain :allocate, :foreign_key_associations
          alias_method_chain :new, :foreign_key_associations
          alias_method_chain :reflections, :foreign_key_associations
        end
      end

      def inherited(child)
        load_foreign_key_associations unless self == ActiveRecord::Base
        super
      end

      def allocate_with_foreign_key_associations
        load_foreign_key_associations
        allocate_without_foreign_key_associations
      end

      def new_with_foreign_key_associations(*args)
        load_foreign_key_associations
        new_without_foreign_key_associations(*args) { |*block_args| yield(*block_args) if block_given? }
      end

      def reflections_with_foreign_key_associations
        load_foreign_key_associations
        reflections_without_foreign_key_associations
      end

      protected

      def load_foreign_key_associations
        # Don't bother if: it's already been loaded; the class is abstract; not a base class; or the table doesn't exist
        return if @foreign_key_associations_loaded || abstract_class? || !base_class? || name.blank? || !table_exists?
        @foreign_key_associations_loaded = true

        reverse_foreign_keys.each do | foreign_key |
          next unless foreign_key.column_names.size == 1

          column_name = foreign_key.column_names.first
          next unless column_name =~ /^(.*)_id$/

          begin
            referencing_class = compute_type(foreign_key.table_name.classify)
          rescue NameError
            case foreign_key.table_name
            when /^#{table_name}_(.*)$/, /^(.*)_#{table_name}$/
              referencing_table_name = $1
              referencing_class_name = referencing_table_name.classify
              referencing_class = compute_type(referencing_class_name)

              association_id = referencing_class.name.demodulize.underscore
              association_id = $1 if association_id =~ /^#{self.name.underscore.singularize}_(.*)$/
              association_id = association_id.pluralize.to_sym

              has_and_belongs_to_many association_id, :class_name => referencing_class.name, :join_table => foreign_key.table_name unless method_defined?(association_id)
            else
              raise
            end
          end

          referencing_class.load_foreign_key_associations
        end

        foreign_keys.each do | foreign_key |
          next unless foreign_key.column_names.size == 1

          column_name = foreign_key.column_names.first
          next unless column_name =~ /^(.*)_id$/

          columns = columns_hash
          column = columns[column_name]

          association_id = $1.to_sym
          references_class_name = foreign_key.references_table_name.classify
          references_class = compute_type(references_class_name)

          # belongs_to
          belongs_to association_id, :class_name => references_class_name, :foreign_key => column_name unless method_defined?(association_id)

          # has_one/has_many
          association_id = self.name.demodulize.underscore
          association_id = $1 if association_id =~ /^#{references_class_name.underscore.singularize}_(.*)$/

          options = { :class_name => name, :foreign_key => column_name }
          if column.unique? && column.unique_scope.empty?
            association_id = association_id.to_sym
            references_class.has_one(association_id, options) unless references_class.method_defined?(association_id)
          else
            options[:order] = :position if columns.has_key?('position')
            association_id = association_id.pluralize.to_sym
            references_class.has_many(association_id, options) unless references_class.method_defined?(association_id)
          end
        end
      end
    end
  end
end
