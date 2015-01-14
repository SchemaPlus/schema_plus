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

  end
end
