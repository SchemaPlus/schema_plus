module SchemaIndexPlus
  module Middleware
    def self.insert
      SchemaMonkey::Middleware::Migration::Column.prepend Migration::IndexShortcuts
      SchemaMonkey::Middleware::Migration::Index.prepend Migration::NormalizeArgs
      SchemaMonkey::Middleware::Migration::Index.prepend Migration::IgnoreDuplicates
      SchemaMonkey::Middleware::Migration::IndexComponentsSql.append Migration::EnhancedFeatures
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
        {:conditions => :warn, :kind => :using}.each do |deprecated, proper|
          if env.options[deprecated]
            ActiveSupport::Deprecation.warn "ActiveRecord index option #{deprecated.inspect} is deprecated, use #{proper.inspect} instead"
            env.options[proper] = env.options.delete(deprecated)
          end
        end
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
      # SchemaPlus provides the following extra options for PostgreSQL
      # indexes:
      # * +:expression+ - SQL expression to index.  column_name can be nil or ommitted, in which case :name must be provided
      # * +:operator_class+ - an operator class name or a hash mapping column name to operator class name
      # * +:case_sensitive - setting to +false+ is a shorthand for :expression => 'LOWER(column_name)'
      #
      # The <tt>:case_sensitive => false</tt> option ties in with Rails built-in support for case-insensitive searching:
      #    validates_uniqueness_of :name, :case_sensitive => false
      #
      # Since since <tt>:case_sensitive => false</tt> is implemented by
      # using <tt>:expression</tt>, this raises an ArgumentError if both
      # are specified simultaneously.
      #
      def call(env)
        options = env.options
        column_names = env.column_names
        table_name = env.table_name
        adapter = env.adapter

        if env.column_names.empty?
          raise ArgumentError, "No columns and :expression missing from options - cannot create index" unless options[:expression]
          raise ArgumentError, "No columns, and index name not given. Pass :name option" unless options[:name]
        end

        expression = options.delete(:expression)
        operator_classes = options.delete(:operator_class)
        case_insensitive = (options.delete(:case_sensitive) == false)

        if expression
          raise ArgumentError, "Cannot specify :case_sensitive => false with an expression.  Use LOWER(column_name)" if case_insensitive
          expression.strip!
          if m = expression.match(/^using\s+(?<using>\S+)\s*(?<rest>.*)/i)
            options[:using] = m[:using]
            expression = m[:rest]
          end
          if m = expression.match(/^(?<rest>.*)\s+where\s+(?<where>.*)/i)
            options[:where] = m[:where]
            expression = m[:rest]
          end
        end

        continue env

        if operator_classes and not operator_classes.is_a? Hash
          operator_classes = Hash[column_names.map {|name| [name, operator_classes]}]
        end

        if expression
          env.sql.columns = expression.sub(/ ^\( (.*) \) $/x, '\1')
        elsif operator_classes or case_insensitive
          option_strings = Hash[column_names.map {|name| [name, '']}]
          (operator_classes||{}).stringify_keys.each do |column, opclass|
            option_strings[column] += " #{opclass}" if opclass
          end
          option_strings = adapter.send :add_index_sort_order, option_strings, column_names, options

          if case_insensitive
            caseable_columns = adapter.columns(table_name).select { |col| [:string, :text].include?(col.type) }.map(&:name)
            quoted_column_names = column_names.map do |col_name|
              (caseable_columns.include?(col_name.to_s) ? "LOWER(#{adapter.quote_column_name(col_name)})" : adapter.quote_column_name(col_name)) + option_strings[col_name]
            end
          else
            quoted_column_names = column_names.map { |col_name| adapter.quote_column_name(col_name) + option_strings[col_name] }
          end

          env.sql.columns = quoted_column_names.join(', ')
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
