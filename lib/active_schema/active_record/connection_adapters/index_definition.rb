module ActiveSchema
  module ActiveRecord
    module ConnectionAdapters
      module IndexDefinition
        attr_accessor :conditions, :expression, :kind

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
