require 'ostruct'

module ActiveSchema
  module ActiveRecord
    module Associations

      def self.extended(base)
        class << base
          alias_method_chain :allocate, :active_schema_associations
          alias_method_chain :new, :active_schema_associations
          alias_method_chain :reflections, :active_schema_associations
        end
      end

      def inherited(child)
        load_active_schema_associations unless self == ::ActiveRecord::Base
        super
      end

      def allocate_with_active_schema_associations
        load_active_schema_associations
        allocate_without_active_schema_associations
      end

      def new_with_active_schema_associations(*args)
        load_active_schema_associations
        new_without_active_schema_associations(*args) { |*block_args| yield(*block_args) if block_given? }
      end

      def reflections_with_active_schema_associations
        load_active_schema_associations
        reflections_without_active_schema_associations
      end

      protected

      def load_active_schema_associations
        return unless active_schema_config.associations.auto_create?

        # Don't bother if: it's already been loaded; the class is abstract; not a base class; or the table doesn't exist
        return if @active_schema_associations_loaded || abstract_class? || !base_class? || !table_exists?
        @active_schema_associations_loaded = true

        reverse_foreign_keys.each do | foreign_key |
          if foreign_key.table_name =~ /^#{table_name}_(.*)$/ || foreign_key.table_name =~ /^(.*)_#{table_name}$/
            _define_association(:has_and_belongs_to_many, foreign_key, $1)
          else
            _define_association(:has_one_or_many, foreign_key)
          end
        end

        foreign_keys.each do | foreign_key |
          _define_association(:belongs_to, foreign_key)
        end
      end
      private

      def _define_association(macro, fk, referencing_table_name = nil)
        return unless fk.column_names.size == 1

        referencing_table_name ||= fk.table_name

        column_name = fk.column_names.first
        association_name = column_name.sub(/_id$/, '')
        references_name = fk.references_table_name.singularize
        referencing_name = referencing_table_name.singularize

        references_class_name = references_name.classify
        referencing_class_name = referencing_name.classify

        references_concise = _strip_name(references_name, referencing_name)
        referencing_concise = _strip_name(referencing_name, references_name)

        case association_name
        when references_name
          belongs_to = references_concise
          has_one = referencing_concise
          has_many = referencing_concise.pluralize
        when /(.*)_#{references_name}$/, /(.*)_#{references_concise}$/
          label = $1
          belongs_to = "#{label}_#{references_concise}"
          has_one = "#{referencing_concise}_as_#{label}"
          has_many = "#{referencing_concise.pluralize}_as_#{label}"
        when /^#{references_name}_(.*)$/, /^#{references_concise}_(.*)$/
          label = $1
          belongs_to = "#{references_concise}_#{label}"
          has_one = "#{referencing_concise}_as_#{label}"
          has_many = "#{referencing_concise.pluralize}_as_#{label}"
        else
          belongs_to = association_name
          has_one = "#{referencing_concise}_as_#{association_name}"
          has_many = "#{referencing_concise.pluralize}_as_#{association_name}"
        end

        case macro
        when :has_and_belongs_to_many
          name = has_many
          opts = {:class_name => referencing_class_name, :join_table => fk.table_name}
        when :belongs_to
          name = belongs_to
          opts = {:class_name => references_class_name, :foreign_key => column_name}
        when :has_one_or_many
          opts = {:class_name => referencing_class_name, :foreign_key => column_name}
          # use connection.indexes and connection.colums rather than class
          # methods of the referencing class because using the class
          # methods would require getting the class -- which might trigger
          # an autoload which could start some recursion making things much
          # harder to debug.
          if connection.indexes(referencing_table_name, "#{referencing_table_name} Indexes").any?{|index| index.unique && index.columns == [column_name]}
            macro = :has_one
            name = has_one
          else
            macro = :has_many
            name = has_many
            if connection.columns(referencing_table_name, "#{referencing_table_name} Columns").any?{ |col| col.name == 'position' }
              opts[:order] = :position
            end
          end
        end
        name = name.to_sym
        if name == :type or !method_defined?(name)
          send macro, name, opts
        end
      end

      def _strip_name(string, name)
        if string =~ /^#{name}_(.*)$/
          string = $1
        elsif string =~ /(.*)_#{name}$/
          string = $1
        end
        string
      end
    end
  end
end
