module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters
      module IndexDefinition
        def self.included(base)
          base.alias_method_chain :initialize, :schema_plus
        end
        
        attr_accessor :conditions, :expression, :kind

        def initialize_with_schema_plus(*args)
          # same args as add_index(table_name, column_names, options={})
          if args.length == 2 or (args.length == 3 && Hash === args.last)
            table_name, column_names, options = args + [{}]
            initialize_without_schema_plus(table_name, options[:name], options[:unique], column_names, options[:lengths])
            self.conditions = options[:conditions]
            self.expression = options[:expression]
            self.kind = options[:kind]
            self.case_sensitive = options[:case_sensitive]
          else # backwards compatibility
            initialize_without_schema_plus(*args)
          end
        end

        def case_sensitive?
          @case_sensitive.nil? ? true : @case_sensitive
        end

        def case_sensitive=(case_sensitive)
          @case_sensitive = case_sensitive
        end

        def opts
          opts = {}
          opts[:name]           = name unless name.nil?
          opts[:unique]         = unique unless unique.nil?
          opts[:lengths]        = lengths unless lengths.nil?
          opts[:conditions]     = conditions unless conditions.nil?
          opts[:expression]     = expression unless expression.nil?
          opts[:kind]           = kind unless kind.nil?
          opts[:case_sensitive] = case_sensitive? unless @case_sensitive.nil?
          opts
        end
      end
    end
  end
end
