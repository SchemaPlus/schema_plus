module ActiveSchema
  module ActiveRecord
    module SchemaValidations

      def inherited(child)
        super
        child.load_schema_validations
      end

      def belongs_to(association_id, *args)
       super
       load_association_validations(association_id)
      end

      def schema_validations(options = {})
        column_names = []
        if options[:only]
          column_names = options[:only]
          @schema_validations_column_include = true
        elsif options[:except]
          column_names = options[:except]
          @schema_validations_column_include = false
        else
          return
        end

        @schema_validations_column_names = Array(column_names).map(&:to_s)
      end

      def load_schema_validations
        # Don't bother if: it's already been loaded; the class is abstract; not a base class; or the table doesn't exist
        return if @schema_validations_loaded || abstract_class? || !base_class? || name.blank? || !table_exists?
        load_column_validations
        @schema_validations_loaded = true
      end

      private

      def load_column_validations
        content_columns.each do |column|
          next unless validates?(column)

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

      def load_association_validations(association_id)
        association = reflect_on_association(association_id)
        column = columns_hash[association.primary_key_name]
        return unless validates?(column)

        # NOT NULL constraints
        validates_presence_of association.name if column.required_on

        # UNIQUE constraints
        add_uniqueness_validation(column) if column.unique?
      end

      def add_uniqueness_validation(column)
        scope = column.unique_scope.map(&:to_sym)
        condition = :"#{column.name}_changed?"
        validates_uniqueness_of column.name.to_sym, :scope => scope, :allow_nil => true, :if => condition
      end

      def validates?(column)
        column.name !~ /^(((created|updated)_(at|on))|position)$/ &&
          (@schema_validations_column_names.nil? || @schema_validations_column_names.include?(column.name) == @schema_validations_column_include)
      end
    end
  end
end
