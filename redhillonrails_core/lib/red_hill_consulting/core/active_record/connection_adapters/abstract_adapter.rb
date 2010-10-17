module RedHillConsulting::Core::ActiveRecord::ConnectionAdapters
  module AbstractAdapter
    def self.included(base)
      base.alias_method_chain :initialize, :redhillonrails_core
      base.alias_method_chain :drop_table, :redhillonrails_core
    end
    
    def initialize_with_redhillonrails_core(*args)
      initialize_without_redhillonrails_core(*args)
      adapter = nil
      case adapter_name
      when 'MySQL' 
        adapter = 'MysqlAdapter'
      when 'PostgreSQL' 
        adapter = 'PostgresqlAdapter'
      when 'SQLite' 
        adapter = 'SqliteAdapter'
      end
      if adapter 
        adapter_module = RedHillConsulting::Core::ActiveRecord::ConnectionAdapters.const_get(adapter)
        self.class.send(:include, adapter_module) unless self.class.include?(adapter_module)
      end
    end
    
    def create_view(view_name, definition)
      execute "CREATE VIEW #{view_name} AS #{definition}"
    end
    
    def drop_view(view_name)
      execute "DROP VIEW #{view_name}"
    end
    
    def views(name = nil)
      []
    end
    
    def view_definition(view_name, name = nil)
    end

    def foreign_keys(table_name, name = nil)
      []
    end

    def reverse_foreign_keys(table_name, name = nil)
      []
    end

    def add_foreign_key(table_name, column_names, references_table_name, references_column_names, options = {})
      foreign_key = ForeignKeyDefinition.new(options[:name], table_name, column_names, ActiveRecord::Migrator.proper_table_name(references_table_name), references_column_names, options[:on_update], options[:on_delete], options[:deferrable])
      execute "ALTER TABLE #{table_name} ADD #{foreign_key}"
    end

    def remove_foreign_key(table_name, foreign_key_name, options = {})
      execute "ALTER TABLE #{table_name} DROP CONSTRAINT #{foreign_key_name}"
    end

    def drop_table_with_redhillonrails_core(name, options = {})
      reverse_foreign_keys(name).each { |foreign_key| remove_foreign_key(foreign_key.table_name, foreign_key.name, options) }
      drop_table_without_redhillonrails_core(name, options)
    end

    def supports_partial_indexes?
      false
    end

  end
end
