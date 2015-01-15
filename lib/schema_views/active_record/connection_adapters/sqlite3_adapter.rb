module SchemaViews
  module ActiveRecord
    module ConnectionAdapters
      module Sqlite3Adapter
        def self.included(base)
          base.class_eval do
            alias_method_chain :tables, :schema_views
          end
        end

        def tables_with_schema_views(name=nil, *args)
          tables_without_schema_views(name, *args) - views(name)
        end

        def views(name = nil)
          execute("SELECT name FROM sqlite_master WHERE type='view'", name).collect{|row| row["name"]}
        end

        def view_definition(view_name, name = nil)
          sql = execute("SELECT sql FROM sqlite_master WHERE type='view' AND name=#{quote(view_name)}", name).collect{|row| row["sql"]}.first
          sql.sub(/^CREATE VIEW \S* AS\s+/im, '') unless sql.nil?
        end

      end
    end
  end
end
