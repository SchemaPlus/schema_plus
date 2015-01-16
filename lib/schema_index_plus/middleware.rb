module SchemaIndexPlus
  module Middleware
    def self.insert
      SchemaMonkey::Middleware::Migration::Column.prepend Migration::IndexShortcuts
      SchemaMonkey::Middleware::Migration::Index.prepend Migration::NormalizeArgs
      SchemaMonkey::Middleware::Migration::Index.prepend Migration::IgnoreDuplicates
      SchemaMonkey::Middleware::Migration::Index.append Migration::EnhancedFeatures
      SchemaMonkey::Middleware::Dumper::Table.append Dumper::InlineIndexes
    end
  end

  module Migration
    class IndexShortcuts < SchemaMonkey::Middleware::Base
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

    class EnhancedFeatures < SchemaMonkey::Middleware::Base
      def call(env)
        if env.caller.respond_to? :add_index_plus
          env.caller.add_index_plus env.table_name, env.column_names, env.options
          # do NOT continue, we've added the index ourselves
        else
          continue env
        end
      end
    end
  end

  module Dumper
    class InlineIndexes < SchemaMonkey::Middleware::Base
      def call(env)
        continue env

        # TODO: if there is more than one index on a single column, should
        # only put one of them in the table statements; the rest need to
        # be left in the table.   (Because Rails' implementation of t.index
        # stores the index data indexed by column name, so you only get
        # one.)

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
