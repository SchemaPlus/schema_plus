module SchemaAutoForeignKeys
  module Middleware
    module Migration

      module Column

        def before(env)
          config = (env.caller.try(:schema_plus_config) || SchemaPlus::ForeignKeys.config)
          set_foreign_key(env) if auto_fk?(env, config)
          set_auto_index(env) if auto_index?(env, config)
        end

        def after(env)
          remove_auto_index(env) if env.operation == :change and remove_auto_index?(env)
        end

        private

        def auto_fk?(env, config)
          return false if env.options.include? :foreign_key
          return false unless config.auto_create?
          return true if env.type == :reference
          return false if env.implements_reference
          return true if env.column_name.to_s =~ /_id$/ # later on add a config option for this
        end

        def auto_index?(env, config)
          return false if env.options.include? :index
          return false unless env.options[:foreign_key]
          return true if config.auto_index?
        end

        def remove_auto_index?(env)
          env.options.include? :foreign_key and not env.options[:foreign_key]
        end

        def set_foreign_key(env)
          env.options[:foreign_key] = true
        end

        def set_auto_index(env)
          env.options[:index] = { name: auto_index_name(env) }
        end

        def remove_auto_index(env)
          env.caller.remove_index(env.table_name, :name => auto_index_name(env), :column => env.column_name, :if_exists => true)
        end

        def auto_index_name(env)
          SchemaAutoForeignKeys.auto_index_name(env.table_name, env.column_name)
        end

      end
    end
  end

  def self.auto_index_name(from_table, column_name)
    "fk__#{fixup_schema_name(from_table)}_#{Array.wrap(column_name).join('_and_')}"
    # this should enforce a maximum length
  end

  def self.fixup_schema_name(table_name)
    # replace . with _
    table_name.to_s.gsub(/[.]/, '_')
  end
end
