module SchemaPlus::ForeignKeys
  module Middleware
    module Migration

      module CreateTable
        def around(env)
          if (original_block = env.block)
            config_options = env.options.delete(:foreign_keys) || {}
            env.block = -> (table_definition) {
              table_definition.schema_plus_config = SchemaPlus::ForeignKeys.config.merge(config_options)
              original_block.call table_definition
            }
          end
          yield env
        end
      end

      module Column

        #
        # Column option shortcuts
        #
        def before(env)
          opts = env.options[:foreign_key]

          return if opts == false

          opts = {} if opts == true

          [:references, :on_update, :on_delete, :deferrable].each do |key|
            (opts||={}).reverse_merge!(key => env.options[key]) if env.options.has_key? key
          end

          return if opts.nil?

          if opts.has_key?(:references) && !opts[:references]
            env.options[:foreign_key] = false
            return
          end

          case opts[:references]
          when nil
          when Array
            table, primary_key = opts[:references]
            opts[:references] = table
            opts[:primary_key] ||= primary_key
          end

          env.options[:foreign_key] = opts
        end

        #
        # Add the foreign keys
        #
        def around(env)
          original_options = env.options
          env.options = original_options.dup

          is_reference = (env.type == :reference)
          is_polymorphic = is_reference && env.options[:polymorphic]

          # usurp index creation from AR.  That's necessary to make
          # auto_index work properly
          #REPL index = options.delete(:index) unless is_polymorphic
          #if is_reference
          #  options[:foreign_key] = false
          #  options[:_is_reference] = true
          #end

          # usurp foreign key creation from AR, since it doesn't support
          # all our features
          env.options[:foreign_key] = false 

          yield env

          return if is_polymorphic or env.implements_reference

          env.options = original_options

          add_foreign_keys(env)

        end

        private

        def add_foreign_keys(env)

          if (reverting = env.caller.is_a?(::ActiveRecord::Migration::CommandRecorder) && env.caller.reverting)
            commands_length = env.caller.commands.length
          end

          config = (env.caller.try(:schema_plus_config) || SchemaPlus::ForeignKeys.config)
          fk_opts = get_fk_opts(env, config)

          # remove existing fk and auto-generated index in case of change of fk on existing column
          if env.operation == :change and fk_opts # includes :none for explicitly off
            remove_foreign_key_if_exists(env)
            #REPL remove_auto_index_if_exists(env)
          end

          fk_opts = nil if fk_opts == :none

          #REPL create_index(env, fk_opts, config)
          create_fk(env, fk_opts) if fk_opts

          if reverting
            rev = []
            while env.caller.commands.length > commands_length
              cmd = env.caller.commands.pop
              rev.unshift cmd unless cmd[0].to_s =~ /^add_/
            end
            env.caller.commands.concat rev
          end

        end

        #REPL def auto_index_name(env)
        #REPL   ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.auto_index_name(env.table_name, env.column_name)
        #REPL end

        #REPL def create_index(env, fk_opts, config)
        #REPL   # create index if requested explicity or implicitly due to auto_index
        #REPL   index = env.options[:index]
        #REPL   index = { :name => auto_index_name(env) } if index.nil? and fk_opts && config.auto_index?
        #REPL   return unless index
        #REPL   case env.caller
        #REPL   when ::ActiveRecord::ConnectionAdapters::TableDefinition
        #REPL     env.caller.index(env.column_name, index)
        #REPL   else
        #REPL     env.caller.add_index(env.table_name, env.column_name, index)
        #REPL   end
        #REPL end

        def create_fk(env, fk_opts)
          references = fk_opts.delete(:references)
          case env.caller
          when ::ActiveRecord::ConnectionAdapters::TableDefinition
            env.caller.foreign_key(env.column_name, references, fk_opts)
          else
            env.caller.add_foreign_key(env.table_name, references, fk_opts.merge(:column => env.column_name))
          end
        end

        def get_fk_opts(env, config)
          opts = env.options[:foreign_key]
          return nil if opts.nil?
          return :none if opts == false
          opts = {} if opts == true
          opts[:references] ||= default_table_name(env)
          opts[:on_update] ||= config.on_update
          opts[:on_delete] ||= config.on_delete
          opts
        end

        def remove_foreign_key_if_exists(env)
          env.caller.remove_foreign_key(env.table_name.to_s, column: env.column_name.to_s, :if_exists => true)
        end

        #REPL def remove_auto_index_if_exists(env)
        #REPL   env.caller.remove_index(env.table_name, :name => auto_index_name(env), :column => env.column_name, :if_exists => true)
        #REPL end

        def default_table_name(env)
          if env.column_name.to_s == 'parent_id'
            env.table_name
          else
            name = env.column_name.to_s.sub(/_id$/, '')
            name = name.pluralize if ::ActiveRecord::Base.pluralize_table_names
            name
          end
        end

      end

    end
  end
end

