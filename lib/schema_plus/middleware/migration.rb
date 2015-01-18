module SchemaPlus
  module Middleware
    module Migration

      def self.insert
        SchemaMonkey::Middleware::Migration::Column.prepend Shortcuts
        SchemaMonkey::Middleware::Migration::Column.append AddForeignKeys
      end

      class Shortcuts < SchemaMonkey::Middleware::Base
        def call(env)

          case options = env.options[:foreign_key]
          when false then ;
          when true then env.options[:foreign_key] = {}
          end

          if env.options[:foreign_key]
            [:references, :on_update, :on_delete, :deferrable].each do |key|
              env.options[:foreign_key].reverse_merge!(env.options[key]) if env.options.has_key? key
            end
            env.options[:foreign_key] = false if options.has_key?(:references) and not options[:references]
          end

          continue env

        end
      end

      class AddForeignKeys < SchemaMonkey::Middleware::Base
        def call(env)
          options = env.options
          original_options = options.dup

          is_reference = (env.type == :reference)
          is_polymorphic = is_reference && options[:polymorphic]

          # usurp index creation from AR.  That's necessary to make
          # auto_index work properly
          index = options.delete(:index) unless is_polymorphic
          options[:foreign_key] = false if is_reference

          continue env

          return if is_polymorphic

          env.options = original_options
          env.name = "#{env.name}_id" if is_reference

          config = (env.caller.try(:schema_plus_config) || SchemaPlus.config).foreign_keys

          case env.operation
          when :record then revertable_add_foreign_keys_and_auto_index(env, config)
          else add_foreign_keys_and_auto_index(env, config)
          end

        end

        def add_foreign_keys_and_auto_index(env, config)

          fk_args = get_fk_args(env, config)

          # remove existing fk and auto-generated index in case of change to existing column
          if fk_args # includes :none for explicitly off
            remove_foreign_key_if_exists(table_name, column_name)
            remove_auto_index_if_exists(table_name, column_name)
          end

          fk_args = nil if fk_args == :none

          create_index(env, fk_args, config)
          create_fk(env, fk_args) if fk_args

          if fk_args
            references = fk_args.delete(:references)
            add_foreign_key(table_name, column_name, references.first, references.last, fk_args)
          end

        end

        def create_index(env, fk_args, config)
          # create index if requested explicity or implicitly due to auto_index
          index = env.options[:index]
          if index.nil? and fk_args && config.auto_index?
            index = { :name => ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.auto_index_name(table_name, column_name) }
          end
          case env.operation
          when :define
            env.caller.index(env.name, env.options)
          else
            env.caller.add_index(env.table_name, env.name, env.options)
          end
        end

        def create_fk(env, fk_args)
          references = fk_args.delete(:references)
          case env.operation
          when :define
            env.caller.foreign_key(env.name, reference.first, reference.last, fk_args)
          else
            env.caller.add_foreign_key(env.table_name, env.name, reference.first, reference.last, fk_args)
          end
        end


        def get_fk_args(env, config) #:nodoc:

          args = nil
          column_name = env.name.to_s
          options = env.options

          return :none if options[:foreign_key] == false

          args = options[:foreign_key]
          args ||= {} if config.auto_create? and column_name =~ /_id$/

          return nil if args.nil?

          args[:references] ||= env.table_name if column_name == 'parent_id'

          args[:references] ||= begin
                                  table_name = column_name.sub(/_id$/, '')
                                  table_name = table_name.pluralize if ActiveRecord::Base.pluralize_table_names
                                  table_name
                                end

          args[:references] = [args[:references], :id] unless args[:references].is_a? Array

          args[:on_update] ||= config.on_update
          args[:on_delete] ||= config.on_delete

          args
        end

      end

      protected
      # The only purpose of that method is to provide a consistent intefrace
      # for ColumnOptionsHandler. First argument (table name) is ignored.
      def add_index(_, *args) #:nodoc:
        index(*args)
      end

      # The only purpose of that method is to provide a consistent intefrace
      # for ColumnOptionsHandler. First argument (table name) is ignored.
      def add_foreign_key(_, *args) #:nodoc:
        foreign_key(*args)
      end

      # This is a deliberately empty stub.  The reason for it is that
      # ColumnOptionsHandler is used for changes as well as for table
      # definitions, and in the case of changes, previously existing foreign
      # keys sometimes need to be removed.  but in the case here, that of
      # table definitions, the only reason a foreign key would exist is
      # because we're redefining a table that already exists (via :force =>
      # true).  in which case the foreign key will get dropped when the
      # drop_table gets emitted, so no need to do it immediately.  (and for
      # sqlite3, attempting to do it immediately would raise an error).
      def remove_foreign_key(_, *args) #:nodoc:
      end

      # This is a deliberately empty stub.  The reason for it is that
      # ColumnOptionsHandler will remove a previous index when changing a
      # column.  But we don't do column changes within table definitions.
      # Presumably will be called with :if_exists true.  If not, will raise
      # an error.
      def remove_index(_, options)
        raise "InternalError: remove_index called in a table definition" unless options[:if_exists]
      end
    end
  end
end

