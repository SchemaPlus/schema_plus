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
          fk_options = env.options[:foreign_key]

          case fk_options
          when false then ;
          when true then fk_options = {}
          end

          if fk_options != false # may be nil
            [:references, :on_update, :on_delete, :deferrable].each do |key|
              (fk_options||={}).reverse_merge!(key => env.options[key]) if env.options.has_key? key
            end
          end

          if fk_options and fk_options.has_key?(:references)
            case fk_options[:references]
            when nil, false
              fk_options = false
            when Array then
              table, primary_key = fk_options[:references]
              fk_options[:references] = table
              fk_options[:primary_key] ||= primary_key
            end
          end


          fk_options = false if fk_options and fk_options.has_key?(:references) and not fk_options[:references]

          env.options[:foreign_key] = fk_options
        end

        #
        # Add the foreign keys
        #
        def around(env)
          options = env.options
          original_options = options.dup

          is_reference = (env.type == :reference)
          is_polymorphic = is_reference && options[:polymorphic]

          # usurp index creation from AR.  That's necessary to make
          # auto_index work properly
          index = options.delete(:index) unless is_polymorphic
          if is_reference
            options[:foreign_key] = false
            options[:_is_reference] = true
          end

          yield env

          return if is_polymorphic

          env.options = original_options

          add_foreign_keys_and_auto_index(env)

        end

        private

        def add_foreign_keys_and_auto_index(env)

          if (reverting = env.caller.is_a?(::ActiveRecord::Migration::CommandRecorder) && env.caller.reverting)
            commands_length = env.caller.commands.length
          end

          config = (env.caller.try(:schema_plus_config) || SchemaPlus::ForeignKeys.config)
          fk_args = get_fk_args(env, config)

          # remove existing fk and auto-generated index in case of change of fk on existing column
          if env.operation == :change and fk_args # includes :none for explicitly off
            remove_foreign_key_if_exists(env)
            remove_auto_index_if_exists(env)
          end

          fk_args = nil if fk_args == :none

          create_index(env, fk_args, config)
          create_fk(env, fk_args) if fk_args

          if reverting
            rev = []
            while env.caller.commands.length > commands_length
              cmd = env.caller.commands.pop
              rev.unshift cmd unless cmd[0].to_s =~ /^add_/
            end
            env.caller.commands.concat rev
          end

        end

        def auto_index_name(env)
          ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.auto_index_name(env.table_name, env.column_name)
        end

        def create_index(env, fk_args, config)
          # create index if requested explicity or implicitly due to auto_index
          index = env.options[:index]
          index = { :name => auto_index_name(env) } if index.nil? and fk_args && config.auto_index?
          return unless index
          case env.caller
          when ::ActiveRecord::ConnectionAdapters::TableDefinition
            env.caller.index(env.column_name, index)
          else
            env.caller.add_index(env.table_name, env.column_name, index)
          end
        end

        def create_fk(env, fk_args)
          references = fk_args.delete(:references)
          case env.caller
          when ::ActiveRecord::ConnectionAdapters::TableDefinition
            env.caller.foreign_key(env.column_name, references, fk_args)
          else
            env.caller.add_foreign_key(env.table_name, references, fk_args.merge(:column => env.column_name))
          end
        end


        def get_fk_args(env, config)
          args = nil
          column_name = env.column_name.to_s
          options = env.options

          return :none if options[:foreign_key] == false

          args = options[:foreign_key]
          auto = config.auto_create?
          auto = false if options[:_is_reference] and env.type != :reference # this is a nested call to column() from with reference(); suppress auto-fk
          args ||= {} if auto and column_name =~ /_id$/

          return nil if args.nil?

          args[:references] ||= env.table_name if column_name == 'parent_id'

          args[:references] ||= begin
                                  table_name = column_name.sub(/_id$/, '')
                                  table_name = table_name.pluralize if ::ActiveRecord::Base.pluralize_table_names
                                  table_name
                                end

          args[:on_update] ||= config.on_update
          args[:on_delete] ||= config.on_delete

          args
        end

        def remove_foreign_key_if_exists(env)
          env.caller.remove_foreign_key(env.table_name.to_s, column: env.column_name.to_s, :if_exists => true)
        end

        def remove_auto_index_if_exists(env)
          env.caller.remove_index(env.table_name, :name => auto_index_name(env), :column => env.column_name, :if_exists => true)
        end

      end

    end
  end
end

