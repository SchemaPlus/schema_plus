module SchemaIndexMigration
  module Middleware
    def self.insert
      SchemaMonkey::Middleware::Migration::Column.insert 0, Migration::IndexShortcuts
      SchemaMonkey::Middleware::Dumper::Table.use Dumper::InlineIndexes
    end
  end

  module Migration
    class IndexShortcuts < SchemaMonkey::Middleware::Base
      def call(env)
        options = env.options
        [:index, :_index].each do |key|
          case options[key]
          when true then options[key] = {}
          when :unique then options[key] = { :unique => true }
          when Hash
            if options[key][:length].is_a? Hash
              options[key][:length].stringify_keys!
            end
          end
        end
        @app.call env
      end
    end
  end

  module Dumper
    class InlineIndexes < SchemaMonkey::Middleware::Base
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
