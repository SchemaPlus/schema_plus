module SchemaViews
  module Middleware
    def self.insert
        SchemaMonkey::Middleware::Dumper::Tables.insert 0, DumpViews
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
      @app.call env

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
