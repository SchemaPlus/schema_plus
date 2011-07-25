module SchemaPlus
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc "Copy schema_plus initializer"
      source_root File.expand_path('../templates', __FILE__)

      def copy_initializers
        copy_file 'schema_plus.rb', 'config/initializers/schema_plus.rb'
      end

    end
  end
end
