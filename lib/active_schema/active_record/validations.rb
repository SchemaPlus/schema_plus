module ActiveSchema
  module ActiveRecord
      module Validations

        def inherited(klass)
          if self == ::ActiveRecord::Base
            klass.instance_eval do

              # create a callback to load the validations before validation
              # happens.  the callback deletes itself after use (just to
              # eliminate the callback overhead).
              before_validation :load_schema_validations
              private
              define_method :load_schema_validations do
                self.class.send :load_schema_validations
                self.class.skip_callback :validation, :before, :load_schema_validations
              end
            end
          end
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
        def active_schema(*)
          super
          return unless create_schema_validations?
          set_possible_validations
          @schema_validated_columns = schema_validations_filter!(@schema_validated_columns, schema_validations_excluded_columns)
          @schema_validated_associations = schema_validations_filter!(@schema_validated_associations, schema_validations_excluded_associations)
          load_schema_validations
        end

        private

        def load_schema_validations
          # Don't bother if: it's already been loaded; the class is abstract; not a base class; or the table doesn't exist
          return unless create_schema_validations?
          set_possible_validations
          load_column_validations(@schema_validated_columns)
          load_association_validations(@schema_validated_associations)
          @schema_validations_loaded = true
        end

        def set_possible_validations
          @schema_validated_columns ||= content_columns.dup
          @schema_validated_associations ||= reflect_on_all_associations(:belongs_to).dup
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

        def create_schema_validations?
          active_schema_config.validations.auto_create? && !(@schema_validations_loaded || abstract_class? || name.blank? || !table_exists?)
        end

        def schema_validations_excluded_columns
          @schema_validations_excluded_columns ||= %w[created_at updated_at created_on updated_on]
        end

        def schema_validations_excluded_associations
          @schema_validated_associations ||= []
        end

        def schema_validations_filter!(fields, default_excludes)
          if filtered_fields = active_schema_config.validations.only
            filter_method = :select
          elsif filtered_fields = active_schema_config.validations.except
            filter_method = :reject
          else
            return
          end
          filtered_fields = Array(filtered_fields).collect(&:to_sym)
          fields.send(filter_method) do |field|
            filtered_fields.include?(field.name.to_sym)
          end
        end

      end

    end
  end
