require 'redhillonrails_core'
ActiveRecord::Base.send(:include, RedHillConsulting::AutomaticForeignKey::ActiveRecord::Base)
ActiveRecord::Migration.send(:include, RedHillConsulting::AutomaticForeignKey::ActiveRecord::Migration)
ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, RedHillConsulting::AutomaticForeignKey::ActiveRecord::ConnectionAdapters::TableDefinition)
