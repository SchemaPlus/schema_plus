module AutomaticForeignKey
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc "Copy automatic foreign key default files"
      source_root File.expand_path('../templates', __FILE__)

      def copy_initializers
        copy_file 'automatic_foreign_key.rb', 'config/initializers/automatic_foreign_key.rb'
      end

    end
  end
end
