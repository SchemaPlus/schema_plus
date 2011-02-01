require 'ostruct'

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
          if foreign_key.table_name =~ /^#{table_name}_(.*)$/ || foreign_key.table_name =~ /^(.*)_#{table_name}$/
            if info = _association_info(foreign_key, $1)
              has_and_belongs_to_many info.has_many, :class_name => info.referencing_class.name, :join_table => foreign_key.table_name unless method_defined?(info.has_many)
            end
          else
            _define_association(foreign_key)
          end
        end

        foreign_keys.each do | foreign_key |
          _define_association(foreign_key)
        end
      end

      private

      def _define_association(fk)
          if info = _association_info(fk)
            columns = info.referencing_class.columns_hash
            column = columns[info.column_name]

            column_name = fk.column_names.first

            # belongs_to
            info.referencing_class.belongs_to info.belongs_to, :class_name => info.references_class.name, :foreign_key => info.column_name unless info.referencing_class.method_defined?(info.belongs_to) and info.belongs_to != :type

            # has_one/has_many
            options = { :class_name => info.referencing_class.name, :foreign_key => info.column_name }
            if column.unique? && column.unique_scope.empty?
              info.references_class.has_one(info.has_one, options) unless info.references_class.method_defined?(info.has_one) and info.has_one != :type
            else
              options[:order] = :position if columns.has_key?('position')
              info.references_class.has_many(info.has_many, options) unless info.references_class.method_defined?(info.has_many)
            end
            info.referencing_class.load_foreign_key_associations
            info.references_class.load_foreign_key_associations
          end
      end


      def _association_info(fk, referencing_table_name=nil)
        return nil unless fk.column_names.size == 1

        column_name = fk.column_names.first
        association_name = column_name.sub(/_id$/, '')
        references_name = fk.references_table_name.singularize
        referencing_name = (referencing_table_name || fk.table_name).singularize.underscore

        references_concise = _strip_name(references_name, referencing_name)
        referencing_concise = _strip_name(referencing_name, references_name)

        references_class = compute_type(references_name.classify) rescue nil
        referencing_class = compute_type(referencing_name.classify) rescue nil

        return nil unless references_class && referencing_class

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

        OpenStruct.new(
          :column_name => column_name,
          :belongs_to => belongs_to.to_sym,
          :has_one => has_one.to_sym,
          :has_many => has_many.to_sym,
          :references_name => references_name,
          :references_class => references_class,
          :referencing_name => referencing_name,
          :referencing_class => referencing_class
        )
      end

      def _strip_name(string, *names)
        names.each do |name|
          name = name.underscore.singularize
          if string =~ /^#{name}_(.*)$/
            string = $1
          elsif string =~ /(.*)_#{name}$/
            string = $1
          end
        end
        string
      end
    end
  end
end
