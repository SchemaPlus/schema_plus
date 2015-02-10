module SchemaPlusForeignKeys
  module Middleware
    module Dumper

      # index and foreign key constraint definitions are dumped
      # inline in the create_table block.  (This is done for elegance, but
      # also because Sqlite3 does not allow foreign key constraints to be
      # added to a table after it has been defined.)

      module Tables

        def before(env)

          @inline_fks = Hash.new{ |h, k| h[k] = [] }
          @backref_fks = Hash.new{ |h, k| h[k] = [] }

          env.connection.tables.each do |table|
            @inline_fks[table] = env.connection.foreign_keys(table)
            env.dump.depends(table, @inline_fks[table].collect(&:to_table))
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
        end

        # Ignore the foreign key dumps at the end of the schema; we'll put them in/near their tables
        def after(env)
          env.dump.final.reject!(&it =~/foreign_key/)
        end

        private

        def break_fk_cycles(env) #:nodoc:
          env.dump.strongly_connected_components.select{|component| component.size > 1}.each do |tables|
            table = tables.sort.first
            backref_fks = @inline_fks[table].select{|fk| tables.include?(fk.to_table)}
            @inline_fks[table] -= backref_fks
            env.dump.dependencies[table] -= backref_fks.collect(&:to_table)
            backref_fks.each do |fk|
              @backref_fks[fk.to_table] << fk
            end
          end
        end

      end

      module Table
        def after(env)
          dumped = {}
          env.table.columns.each do |column|
            if (foreign_key = env.dump.data.inline_fks[env.table.name].find(&its.column.to_s == column.name))
              column.add_option foreign_key.to_dump(column: true)
              dumped[foreign_key] = true
            end
            if (foreign_key = env.dump.data.backref_fks.values.flatten.find{|fk| fk.from_table.to_s == env.table.name && fk.column.to_s == column.name})
              column.add_comment "foreign key references #{foreign_key.to_table.inspect} (below)"
            end
          end
          env.table.statements += env.dump.data.inline_fks[env.table.name].map { |foreign_key|
            foreign_key.to_dump(inline: true) unless dumped[foreign_key]
          }.compact.sort
          env.table.trailer += env.dump.data.backref_fks[env.table.name].map { |foreign_key|
            foreign_key.to_dump
          }.sort
        end
      end
    end

  end
end
