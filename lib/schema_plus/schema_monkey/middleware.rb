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
      Env = Struct.new(:adapter, :sql, :name, :binds)
    end

    module AddColumnOptions
      extend Stack
      Env = Struct.new(:adapter, :sql, :options, :schema_creation) do
        def options_include_default?
          @include_default ||= schema_creation.send :options_include_default?, options
        end
      end
    end

  end
end
