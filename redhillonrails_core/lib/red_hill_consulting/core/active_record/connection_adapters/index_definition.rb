module RedHillConsulting::Core::ActiveRecord::ConnectionAdapters
	module IndexDefinition
		def case_sensitive?
			@case_sensitive.nil? ? true : @case_sensitive
		end

		def case_sensitive=(case_sensitive)
			@case_sensitive = case_sensitive
		end

		def conditions=(conditions)
			@conditions = conditions
		end

		def conditions
			@conditions
		end
	end
end
