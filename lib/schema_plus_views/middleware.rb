module SchemaPlusViews
  module Middleware
    def self.insert
        SchemaMonkey::Middleware::Dumper::Tables.prepend DumpViews
    end
    module Mysql
      def self.insert
        SchemaMonkey::Middleware::Query::Tables.append FilterOutViews
      end
    end
    module Sqlite3
      def self.insert
        SchemaMonkey::Middleware::Query::Tables.append FilterOutViews
      end
    end
  end

  class FilterOutViews < SchemaMonkey::Middleware::Base
    def call(env)
      continue env
      env.tables -= env.connection.views(env.query_name)
    end
  end

  class DumpViews < SchemaMonkey::Middleware::Base

    # quacks like a SchemaMonkey Dump::Table
    class View < KeyStruct[:name, :definition]
      def assemble(stream)
        stream.puts("  create_view #{name.inspect}, #{definition.inspect}, :force => true\n")
      end
    end

    def call(env)
      continue env

      re_view_referent = %r{(?:(?i)FROM|JOIN) \S*\b(\S+)\b}
      env.connection.views.each do |view_name|
        next if env.dumper.ignored?(view_name)
        view = View.new(name: view_name, definition: env.connection.view_definition(view_name))
        env.dump.tables[view.name] = view
        env.dump.depends(view.name, view.definition.scan(re_view_referent).flatten)
      end
    end

  end
end
