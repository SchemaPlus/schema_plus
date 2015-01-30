module SchemaPlusViews
  module ActiveRecord
    module ConnectionAdapters
      module Sqlite3Adapter

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
