module SchemaPlus
  module ActiveRecord
      module Validations

        def inherited(klass) #:nodoc:
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
        def schema_plus(*) #:nodoc:
          super
          load_schema_validations
        end

        private

        def load_schema_validations #:nodoc:
          # Don't bother if: it's already been loaded; the class is abstract; not a base class; or the table doesn't exist
          return unless create_schema_validations?
          
          load_column_validations
          load_association_validations
          @schema_validations_loaded = true
        end

        def load_column_validations #:nodoc:
          content_columns.each do |column|
            name = column.name.to_sym

            # Data-type validation
            if column.type == :integer
              validate_logged :validates_numericality_of, name, :allow_nil => true, :only_integer => true
            elsif column.number?
              validate_logged :validates_numericality_of, name, :allow_nil => true
            elsif column.text? && column.limit
              validate_logged :validates_length_of, name, :allow_nil => true, :maximum => column.limit
            end

            # NOT NULL constraints
            if column.required_on
              if column.type == :boolean
                validate_logged :validates_inclusion_of, name, :in => [true, false], :message => :blank
              else
                validate_logged :validates_presence_of, name
              end
            end

            # UNIQUE constraints
            add_uniqueness_validation(column) if column.unique?
          end
        end

        def load_association_validations #:nodoc:
          reflect_on_all_associations(:belongs_to).each do |association|
            # :primary_key_name was deprecated (noisily) in rails 3.1
            foreign_key_method = (association.respond_to? :foreign_key) ?  :foreign_key : :primary_key_name
            column = columns_hash[association.send(foreign_key_method).to_s]
            next unless column

            # NOT NULL constraints
            validate_logged :validates_presence_of, association.name if column.required_on

            # UNIQUE constraints
            add_uniqueness_validation(column) if column.unique?
          end
        end

        def add_uniqueness_validation(column) #:nodoc:
          scope = column.unique_scope.map(&:to_sym)
          condition = :"#{column.name}_changed?"
          name = column.name.to_sym
          validate_logged :validates_uniqueness_of, name, :scope => scope, :allow_nil => true, :if => condition
        end

        def create_schema_validations? #:nodoc:
          schema_plus_config.validations.auto_create? && !(@schema_validations_loaded || abstract_class? || name.blank? || !table_exists?)
        end

        def validate_logged(method, arg, opts={}) #:nodoc:
          if _filter_validation(method, arg) 
            msg = "SchemaPlus validations: #{self.name}.#{method} #{arg.inspect}"
            msg += ", #{opts.inspect[1...-1]}" if opts.any?
            logger.info msg
            send method, arg, opts
          end
        end

        def _filter_validation(macro, name) #:nodoc:
          config = schema_plus_config.validations
          types = [macro]
          if match = macro.to_s.match(/^validates_(.*)_of$/) 
            types << match[1].to_sym
          end
          return false if config.only        and not Array.wrap(config.only).include?(name)
          return false if config.except      and     Array.wrap(config.except).include?(name)
          return false if config.only_type   and not (Array.wrap(config.only_type) & types).any?
          return false if config.except_type and     (Array.wrap(config.except_type) & types).any?
          return true
        end

      end

    end
  end
