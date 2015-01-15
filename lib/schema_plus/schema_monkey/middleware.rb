module SchemaMonkey
  module Middleware

    class Base
      def initialize(app)
        @app = app
      end
    end

    module Stack
      def stack
        @stack ||= ::Middleware::Builder.new
      end
      def insert(*args)
        stack.insert(*args)
      end
      def insert_before(*args)
        stack.insert_before(*args)
      end
      def insert_after(*args)
        stack.insert_after(*args)
      end
      def use(*args)
        stack.use(*args)
      end
      def call(env)
        stack.call(env)
      end
    end

    module ExecCache
      extend Stack
      Env = KeyStruct[:adapter, :sql, :name, :binds]
    end

    module AddColumnOptions
      extend Stack
      class Env < KeyStruct[:adapter, :sql, :options, :schema_creation]
        def options_include_default?
          @include_default ||= schema_creation.send :options_include_default?, options
        end
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
