begin
  require 'active_support'
  require 'redhillonrails_core'
rescue
  gem 'redhillonrails_core'
  require 'redhillonrails_core'
end

module AutomaticForeignKey
  module ActiveRecord
    autoload :Base, 'automatic_foreign_key/active_record/base'
    autoload :Migration, 'automatic_foreign_key/active_record/migration'

    module ConnectionAdapters
      autoload :TableDefinition, 'automatic_foreign_key/active_record/connection_adapters/table_definition'
      autoload :SchemaStatements, 'automatic_foreign_key/active_record/connection_adapters/schema_statements'
    end

  end

  # Default FK update action 
  mattr_accessor :on_update
  
  # Default FK delete action 
  mattr_accessor :on_delete

  # Create an index after creating FK (default false)
  mattr_accessor :auto_index
  @@auto_index = nil

  def self.options_for_index(index)
    index.is_a?(Hash) ? index : {}
  end

  def self.set_default_update_and_delete_actions!(options)
    options[:on_update] = options.fetch(:on_update, AutomaticForeignKey.on_update)
    options[:on_delete] = options.fetch(:on_delete, AutomaticForeignKey.on_delete)
  end

end

ActiveRecord::Base.send(:include, AutomaticForeignKey::ActiveRecord::Base)
ActiveRecord::Migration.send(:include, AutomaticForeignKey::ActiveRecord::Migration)
ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, AutomaticForeignKey::ActiveRecord::ConnectionAdapters::TableDefinition)
ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, AutomaticForeignKey::ActiveRecord::ConnectionAdapters::SchemaStatements)
