module SchemaIndexPlus
  module Middleware
    module Dumper

      def self.insert
        SchemaMonkey::Middleware::Dumper::Table.append InlineIndexes
      end

      class InlineIndexes < SchemaMonkey::Middleware::Base
        def call(env)
          continue env

          # TODO: if there is more than one index on a single column, should
          # only put one of them in the table statements; the rest need to
          # be left in the table.   (Because Rails' implementation of t.index
          # stores the index data indexed by column name, so you only get
          # one.)
          # TODO: maybe define the inline indexes using column options
          # rather than t.index

          # we'll put the index definitions inline
          env.table.trailer.reject!{ |s| s =~ /^\s*add_index\b/ }

          env.table.statements += env.connection.indexes(env.table.name).collect{ |index|
            dump = "t.index"
            dump << " #{index.columns.inspect}," unless index.columns.blank?
            dump << " :name => #{index.name.inspect}"
            dump << ", :unique => true" if index.unique
            dump << ", :using => \"#{index.using}\"" unless index.using.blank?
            unless index.columns.blank?
              dump << ", :case_sensitive => false" unless index.case_sensitive?
              dump << ", :where => #{index.where.inspect}" unless index.where.blank?
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
end
