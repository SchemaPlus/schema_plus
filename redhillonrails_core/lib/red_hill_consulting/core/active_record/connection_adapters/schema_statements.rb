module RedHillConsulting::Core::ActiveRecord::ConnectionAdapters
	module SchemaStatements
		def self.included(base)
			base.module_eval do
				alias_method_chain :create_table, :redhillonrails_core
			end
		end

		def create_table_with_redhillonrails_core(name, options = {})
			if options.include?(:comment)
				options = options.dup
				comment = options.delete(:comment)
			end

			create_table_without_redhillonrails_core(name, options) do |table_defintion|
				table_defintion.name = name
				yield table_defintion if block_given?
			end

			set_table_comment(name, comment) if comment
		end
	end
end
