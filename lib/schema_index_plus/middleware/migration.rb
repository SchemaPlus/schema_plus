module SchemaIndexPlus
  module Middleware
    module Migration

      def self.insert
        SchemaMonkey::Middleware::Migration::Column.prepend Shortcuts
        SchemaMonkey::Middleware::Migration::Index.prepend NormalizeArgs
        SchemaMonkey::Middleware::Migration::Index.prepend IgnoreDuplicates
      end

      class Shortcuts < SchemaMonkey::Middleware::Base
        def call(env)
          case env.options[:index]
          when true then env.options[:index] = {}
          when :unique then env.options[:index] = { :unique => true }
          end
          continue env
        end
      end

      class NormalizeArgs < SchemaMonkey::Middleware::Base
        def call(env)
          {:conditions => :warn, :kind => :using}.each do |deprecated, proper|
            if env.options[deprecated]
              ActiveSupport::Deprecation.warn "ActiveRecord index option #{deprecated.inspect} is deprecated, use #{proper.inspect} instead"
              env.options[proper] = env.options.delete(deprecated)
            end
          end
          [:length, :order].each do |key|
            case env.options[key]
            when Symbol then env.options[key] = env.options[key].to_s
            when Hash then env.options[key].stringify_keys!
            end
          end
          env.column_names = Array.wrap(env.column_names).map(&:to_s) + Array.wrap(env.options.delete(:with)).map(&:to_s)
          continue env
        end
      end

      class IgnoreDuplicates < SchemaMonkey::Middleware::Base
        # SchemaPlus modifies SchemaStatements::add_index so that it ignores
        # errors raised about add an index that already exists -- i.e. that has
        # the same index name, same columns, and same options -- and writes a
        # warning to the log. Some combinations of rails & DB adapter versions
        # would log such a warning, others would raise an error; with
        # SchemaPlus all versions log the warning and do not raise the error.
        #
        # (This avoids collisions between SchemaPlus's auto index behavior and
        # legacy explicit add_index statements, for platforms that would raise
        # an error.)
        #
        def call(env)
          continue env
        rescue => e
          raise unless e.message.match(/["']([^"']+)["'].*already exists/)
          name = $1
          existing = env.caller.indexes(env.table_name).find{|i| i.name == name}
          attempted = ::ActiveRecord::ConnectionAdapters::IndexDefinition.new(env.table_name, env.column_names, env.options.merge(:name => name))
          raise if attempted != existing
          ::ActiveRecord::Base.logger.warn "[schema_plus] Index name #{name.inspect}' on table #{env.table_name.inspect} already exists. Skipping."
        end
      end

    end
  end
end
