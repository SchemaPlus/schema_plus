module SchemaMonkey
  module Middleware

    class Base
      def initialize(app)
        @app = app
      end
      def continue(env)
        @app.call env
      end
    end

    module Stack
      def stack
        @stack ||= ::Middleware::Builder.new do
          use Root
        end
      end

      def insert_before(*args)
        stack.insert_before(*args)
      end

      def insert_after(*args)
        stack.insert_after(*args)
      end

      def append(*args)
        stack.insert_before(Root, *args)
      end

      def prepend(*args)
        stack.insert(0, *args)
      end

      def start(*args, &block)
        env = self.const_get(:Env).new(*args)
        env.instance_variable_set('@root', block)
        stack.call(env)
      end

      class Root < Base
        def call(env)
          env.instance_variable_get('@root').call(env)
        end
      end
    end

    module Query
      module ExecCache
        extend Stack
        Env = KeyStruct[:adapter, :sql, :name, :binds]
      end
    end

    module Migration

      module Column
        extend Stack
        Env = KeyStruct[:caller, :operation, :table_name, :name, :type, :options]
      end

      module ColumnOptionsSql
        extend Stack
        class Env < KeyStruct[:adapter, :sql, :options, :schema_creation]
          def options_include_default?
            @include_default ||= schema_creation.send :options_include_default?, options
          end
        end
      end

      module Index
        extend Stack
        Env = KeyStruct[:caller, :operation, :table_name, :column_names, :options]
      end

      module IndexComponentsSql
        extend Stack
        Sql = KeyStruct[:name, :type, :columns, :options, :algorithm, :using]
        Env = KeyStruct[:adapter, :table_name, :column_names, :options, sql: Sql.new]
      end

    end

    module Dumper
      module Extensions
        extend Stack
        Env = KeyStruct[:dumper, :connection, :extensions]
      end
      module Tables
        extend Stack
        Env = KeyStruct[:dumper, :connection, :dump]
      end
      module Table
        extend Stack
        Env = KeyStruct[:dumper, :connection, :dump, :table]
      end
    end

  end
end
