module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters
      # 
      # SchemaPlus extends the IndexDefinition object to return information
      # about partial indexes and case sensitivity (i.e. Postgresql
      # support).
      module IndexDefinition
        def self.included(base)  #:nodoc:
          base.alias_method_chain :initialize, :schema_plus
        end
        
        attr_reader :conditions
        attr_reader :expression
        attr_reader :kind

        def case_sensitive?
          @case_sensitive
        end

        def initialize_with_schema_plus(*args) #:nodoc:
          # same args as add_index(table_name, column_names, options)
          if args.length == 3 and Hash === args.last
            table_name, column_names, options = args + [{}]
            initialize_without_schema_plus(table_name, options[:name], options[:unique], column_names, options[:lengths])
            @conditions = options[:conditions]
            @expression = options[:expression]
            @kind = options[:kind]
            @case_sensitive = options.include?(:case_sensitive) ? options[:case_sensitive] : true
          else # backwards compatibility
            initialize_without_schema_plus(*args)
            @case_sensitive = true
          end
        end

        # returns the options as a hash suitable for add_index
        def opts #:nodoc:
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
