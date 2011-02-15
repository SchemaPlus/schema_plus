module ActiveSchema
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc "Install ActiveSchema configuration file"
      source_root File.expand_path('../templates', __FILE__)

      def copy_initializers
        copy_file 'active_schema.rb', 'config/initializers/active_schema.rb'
      end

    end
  end
end
