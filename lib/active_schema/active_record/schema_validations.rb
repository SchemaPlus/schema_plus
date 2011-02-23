require 'active_support/core_ext/class/inheritable_attributes'
require 'active_support/core_ext/module/aliasing'

module ActiveSchema
  module ActiveRecord
    module SchemaValidations

      module Core

        def self.extended(klass)
          # which columns are auto-validated
          klass.class_inheritable_accessor :schema_validated_columns
          # which associations are auto-validated
          klass.class_inheritable_accessor :schema_validated_associations
          # indicates if auto-validations are created already
          klass.class_inheritable_accessor :schema_validations_loaded
          super
        end

        # Adds schema-based validations to model.
        # Attributes as well as associations are validated.
        # For instance if there is column
        #
        #     <code>email NOT NULL</code>
        #
        # defined at database-level it will be translated to
        #
        #     <code>validates_presence_of :email</code>
        #
        # If there is an association named <tt>user</tt>
        # based on <tt>user_id NOT NULL</tt> it will be translated to
        #
        #     <code>validates_presence_of :user</code>
        #
        #  Note it uses the name of association (user) not the column name (user_id).
        #  Only <tt>belongs_to</tt> associations are validated.
        #
        #  This accepts following options:
        #  * :only - auto-validate only given attributes
        #  * :except - auto-validate all but given attributes
        #
        def schema_validations(options = {})
          self.schema_validated_columns ||= possible_schema_validated_columns.dup
          self.schema_validated_associations ||= possible_schema_validated_associations.dup
          schema_validations_filter!(schema_validated_columns, schema_validations_excluded_columns, options)
          schema_validations_filter!(schema_validated_associations, schema_validations_excluded_associations, options)
          load_schema_validations
        end

        protected
        def load_schema_validations(options = {})
          # Don't bother if: it's already been loaded; the class is abstract; not a base class; or the table doesn't exist
          return if schema_validations_loaded || abstract_class? || !base_class? || name.blank? || !table_exists?
          validated_columns = options[:validated_columns] || self.schema_validated_columns
          validated_associations = options[:validated_associations] || self.schema_validated_associations || possible_schema_validated_associations
          load_column_validations(validated_columns)
          load_association_validations(validated_associations)
          self.schema_validations_loaded = true
        end

        def load_column_validations(validated_columns)
          validated_columns.each do |column|
            name = column.name.to_sym

            # Data-type validation
            if column.type == :integer
              validates_numericality_of name, :allow_nil => true, :only_integer => true
            elsif column.number?
              validates_numericality_of name, :allow_nil => true
            elsif column.text? && column.limit
              validates_length_of name, :allow_nil => true, :maximum => column.limit
            end

            # NOT NULL constraints
            if column.required_on
              if column.type == :boolean
                validates_inclusion_of name, :in => [true, false], :message => :blank
              else
                validates_presence_of name
              end
            end

            # UNIQUE constraints
            add_uniqueness_validation(column) if column.unique?
          end
        end

        def load_association_validations(associations)
          associations.each do |association|
            column = columns_hash[association.primary_key_name.to_s]
            next unless column

            # NOT NULL constraints
            validates_presence_of association.name if column.required_on

            # UNIQUE constraints
            add_uniqueness_validation(column) if column.unique?
          end
        end

        def add_uniqueness_validation(column)
          scope = column.unique_scope.map(&:to_sym)
          condition = :"#{column.name}_changed?"
          name = column.name.to_sym
          validates_uniqueness_of name, :scope => scope, :allow_nil => true, :if => condition
        end

        def possible_schema_validated_columns(model = self)
          model.content_columns
        end

        def possible_schema_validated_associations(model = self)
          model.reflect_on_all_associations(:belongs_to)
        end

        def schema_validations_excluded_columns
          @schema_validations_excluded_columns ||= %w[created_at updated_at created_on updated_on]
        end

        def schema_validations_excluded_associations
          @schema_validated_associations ||= []
        end

        def schema_validations_filter!(fields, default_excludes, options)
          if options[:only]
            filter_key, filter_method = :only, :select!
          elsif options[:except]
            filter_key, filter_method = :except, :reject!
          else
            return
          end
          filtered_fields = Array(options[filter_key]).collect(&:to_sym)
          fields.send(filter_method) do |field|
            filtered_fields.include?(field.name.to_sym)
          end
        end

      end # Core

      # When AutoCreate is enabled schema validations are added to model
      # transparently. Otherwise one have to invoke <tt>schema_validations</tt>
      # method inside the model.
      #
      # AutoCreate alias_method_chains <tt>ActiveRecord::Base#new</tt> and
      # <tt>ActiveRecord::Base.instantiate</tt> so it slightly affects
      # performance. To avoid that AutoCreate module is added only when
      # validations.auto_create is enabled.
      module AutoCreate

        def self.extended(klass)
          class << klass
            alias_method_chain :new, :schema_validations
            alias_method_chain :instantiate, :schema_validations
          end
          super
        end

        def inherited(child)
          super
          if self == ::ActiveRecord::Base
            child.schema_validated_columns = possible_schema_validated_columns(child).dup
          end
        end

        def new_with_schema_validations(*args)
          load_schema_validations
          new_without_schema_validations(*args)
        end

        def instantiate_with_schema_validations(record)
          load_schema_validations
          instantiate_without_schema_validations(record)
        end

      end # module AutoCreate


    end
  end
end
