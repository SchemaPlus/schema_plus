require 'tsort'

module SchemaPlus
  module Middleware
    def self.insert
      SchemaMonkey::Middleware::Dumper::Tables.insert 0, FkDependencies
      SchemaMonkey::Middleware::Dumper::Tables.use IgnoreActiveRecordFkDumps
      SchemaMonkey::Middleware::Dumper::Table.use ForeignKeys
      SchemaMonkey::Middleware::Dumper::Table.use Indexes
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

        @app.call env
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
        @app.call env
        env.dump.foreign_keys = []
      end
    end

    #
    # Middleware for individual tables
    #
    class ForeignKeys < SchemaMonkey::Middleware::Base
      def call(env)
        @app.call env
        env.table.statements += env.dump.data.inline_fks[env.table.name].map { |foreign_key|
          foreign_key.to_dump(inline: true)
        }.sort
        env.table.trailer += env.dump.data.backref_fks[env.table.name].map { |foreign_key|
          foreign_key.to_dump(inline: false)
        }.sort
      end
    end

    class Indexes < SchemaMonkey::Middleware::Base
      def call(env)
        @app.call env
        # we'll put the index definitions inline
        env.table.trailer.reject!{ |s| s =~ /^\s*add_index\b/ }

        env.table.statements += env.connection.indexes(env.table.name).collect{ |index|
          dump = "t.index"
          dump << " #{index.columns.inspect}," unless index.columns.blank?
          dump << " :name => #{index.name.inspect}"
          dump << ", :unique => true" if index.unique
          dump << ", :kind => \"#{index.kind}\"" unless index.kind.blank?
          unless index.columns.blank? 
            dump << ", :case_sensitive => false" unless index.case_sensitive?
            dump << ", :conditions => #{index.conditions.inspect}" unless index.conditions.blank?
            index_lengths = index.lengths.compact if index.lengths.is_a?(Array)
            dump << ", :length => #{Hash[*index.columns.zip(index.lengths).flatten].inspect}" if index_lengths.present?
            dump << ", :order => {" + index.orders.map{|column, val| "#{column.inspect} => #{val.inspect}"}.join(", ") + "}" unless index.orders.blank?
            dump << ", :operator_class => {" + index.operator_classes.map{|column, val| "#{column.inspect} => #{val.inspect}"}.join(", ") + "}" unless index.operator_classes.blank?
          else
            dump << ", :expression => #{index.expression.inspect}"
          end
          dump << "\n"
        }.sort
      end
    end
  end
end
