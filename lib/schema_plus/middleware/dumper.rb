module SchemaPlus
  module Middleware

    module Migration
      def self.insert
        SchemaMonkey::Middleware::Migration::Column.append HandleColumn
      end
      class HandleColumn < SchemaMonkey::Middleware::Base
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

          handler = case env.operation
                    when :record then :revertable_schema_plus_handle_column_options
                    else :schema_plus_handle_column_options
                    end

          column_name = env.name.to_s
          column_name += "_id" if env.type == :reference
          env.caller.send handler, env.table_name, column_name, original_options, :config => env.caller.try(:schema_plus_config)
        end
      end

    end

    module Dumper
      def self.insert
        SchemaMonkey::Middleware::Dumper::Tables.prepend FkDependencies
        SchemaMonkey::Middleware::Dumper::Tables.append IgnoreActiveRecordFkDumps
        SchemaMonkey::Middleware::Dumper::Table.append ForeignKeys
      end

      # index and foreign key constraint definitions are dumped
      # inline in the create_table block.  (This is done for elegance, but
      # also because Sqlite3 does not allow foreign key constraints to be
      # added to a table after it has been defined.)

      #
      # Middleware for the collection of tables
      #

      class FkDependencies < SchemaMonkey::Middleware::Base

        def call(env)
          @inline_fks = Hash.new{ |h, k| h[k] = [] }
          @backref_fks = Hash.new{ |h, k| h[k] = [] }

          env.connection.tables.each do |table|
            @inline_fks[table] = env.connection.foreign_keys(table)
            env.dump.depends(table, @inline_fks[table].collect(&:references_table_name))
          end

          # Normally we dump foreign key constraints inline in the table
          # definitions, both for visual cleanliness and because sqlite3
          # doesn't allow foreign key constraints to be added afterwards.
          # But in case there's a cycle in the constraint references, some
          # constraints will need to be broken out then added later.  (Adding
          # constraints later won't work with sqlite3, but that means sqlite3
          # won't let you create cycles in the first place.)
          break_fk_cycles(env) while env.dump.strongly_connected_components.any?{|component| component.size > 1}

          env.dump.data.inline_fks = @inline_fks
          env.dump.data.backref_fks = @backref_fks

          continue env
        end

        def break_fk_cycles(env) #:nodoc:
          env.dump.strongly_connected_components.select{|component| component.size > 1}.each do |tables|
            table = tables.sort.first
            backref_fks = @inline_fks[table].select{|fk| tables.include?(fk.references_table_name)}
            @inline_fks[table] -= backref_fks
            env.dump.dependencies[table] -= backref_fks.collect(&:references_table_name)
            backref_fks.each do |fk|
              @backref_fks[fk.references_table_name] << fk
            end
          end
        end
      end

      class IgnoreActiveRecordFkDumps < SchemaMonkey::Middleware::Base
        # Ignore the foreign key dumps at the end of the schema; we'll put them in/near their tables
        def call(env)
          continue env
          env.dump.foreign_keys = []
        end
      end

      #
      # Middleware for individual tables
      #
      class ForeignKeys < SchemaMonkey::Middleware::Base
        def call(env)
          continue env
          env.table.statements += env.dump.data.inline_fks[env.table.name].map { |foreign_key|
            foreign_key.to_dump(inline: true)
          }.sort
          env.table.trailer += env.dump.data.backref_fks[env.table.name].map { |foreign_key|
            foreign_key.to_dump(inline: false)
          }.sort
        end
      end
    end

  end
end
