module SchemaPlusViews
  module Middleware

    module Dumper
      module Tables

        # Dump views
        def after(env)
          re_view_referent = %r{(?:(?i)FROM|JOIN) \S*\b(\S+)\b}
          env.connection.views.each do |view_name|
            next if env.dumper.ignored?(view_name)
            view = View.new(name: view_name, definition: env.connection.view_definition(view_name))
            env.dump.tables[view.name] = view
            env.dump.depends(view.name, view.definition.scan(re_view_referent).flatten)
          end
        end

        # quacks like a SchemaMonkey Dump::Table
        class View < KeyStruct[:name, :definition]
          def assemble(stream)
            stream.puts("  create_view #{name.inspect}, #{definition.inspect}, :force => true\n")
          end
        end
      end
    end

    module Query
      module Tables

        module Mysql
          def after(env)
            Tables.filter_out_views(env)
          end
        end

        module Sqlite3
          def after(env)
            Tables.filter_out_views(env)
          end
        end

        def self.filter_out_views(env)
          env.tables -= env.connection.views(env.query_name)
        end
      end
    end
  end

end
