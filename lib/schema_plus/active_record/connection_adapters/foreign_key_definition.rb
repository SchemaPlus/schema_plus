if "#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}".to_r < "4.2".to_r
  class ActiveRecord::ConnectionAdapters::ForeignKeyDefinition < Struct.new(:from_table, :to_table, :options) #:nodoc:
    # The name of the foreign key constraint
    def name
      options[:name]
    end

    def column
      options[:column]
    end

    def primary_key
      options[:primary_key] || default_primary_key
    end

    # The ON_DELETE behavior for the constraint.  See above for the
    # possible values.
    def on_delete
      options[:on_delete]
    end

    # The ON_UPDATE behavior for the constraint.  See above for the
    # possible values.
    def on_update
      options[:on_update]
    end

    def custom_primary_key?
      options[:primary_key] != default_primary_key
    end

    private
    def default_primary_key
      "id"
    end
  end
else
  require 'active_record/connection_adapters/abstract/schema_definitions'
end

module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters
      # Instances of this class are returned by the queries ActiveRecord::Base#foreign_keys and ActiveRecord::Base#reverse_foreign_keys (via AbstractAdapter#foreign_keys and AbstractAdapter#reverse_foreign_keys)
      #
      # The on_update and on_delete attributes can take on the following values:
      #   :cascade
      #   :restrict
      #   :set_null
      #   :set_default
      #   :no_action
      #
      # The deferrable attribute can take on the following values:
      #   true
      #   :initially_deferred
      class ForeignKeyDefinition < ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition

        # The list of column names that are constrained (as strings).
        attr_reader :column_names

        # The list of column names (as strings) of the foreign table that are referenced
        # by the constraint
        attr_reader :references_column_names
        # :enddoc:

        ACTIONS = { :cascade => "CASCADE", :restrict => "RESTRICT", :set_null => "SET NULL", :set_default => "SET DEFAULT", :no_action => "NO ACTION" }.freeze

        def initialize(from_table, to_table, options) 
          super
          @from_table = unquote(from_table)
          @to_table = unquote(to_table)
          @column_names = unquote(Array.wrap(options.delete(:column_names)))
          @references_column_names = unquote(Array.wrap(options.delete(:references_column_names)))

          ACTIONS.has_key?(on_update) or raise(ArgumentError, "invalid :on_update action: #{on_update.inspect}") if on_update
          ACTIONS.has_key?(on_delete) or raise(ArgumentError, "invalid :on_delete action: #{on_delete.inspect}") if on_delete
          if ::ActiveRecord::Base.connection.adapter_name =~ /^mysql/i
            raise(NotImplementedError, "MySQL does not support ON UPDATE SET DEFAULT") if on_update == :set_default
            raise(NotImplementedError, "MySQL does not support ON DELETE SET DEFAULT") if on_delete == :set_default
          end
        end

        def table_name
          from_table
        end

        def references_table_name
          to_table
        end

        # True if the constraint is deferrable
        def deferrable
          options[:deferrable]
        end

        # Dumps a definition of foreign key.
        def to_dump(opts={})
          dump = (opts[:inline] ? "  t.foreign_key" : "add_foreign_key #{table_name.inspect},")
          dump << " [#{Array(column_names).collect{ |name| name.inspect }.join(', ')}]"
          dump << ", #{references_table_name.inspect}, [#{Array(references_column_names).collect{ |name| name.inspect }.join(', ')}]"
          dump << ", :on_update => #{on_update.inspect}" if on_update
          dump << ", :on_delete => #{on_delete.inspect}" if on_delete
          dump << ", :deferrable => #{deferrable.inspect}" if deferrable
          dump << ", :name => #{name.inspect}" if name
          dump << "\n"
          dump
        end

        def to_sql
          sql = name ? "CONSTRAINT #{name} " : ""
          sql << "FOREIGN KEY (#{quoted_column_names.join(", ")}) REFERENCES #{quoted_references_table_name} (#{quoted_references_column_names.join(", ")})"
          sql << " ON UPDATE #{ACTIONS[on_update]}" if on_update
          sql << " ON DELETE #{ACTIONS[on_delete]}" if on_delete
          sql << " DEFERRABLE" if deferrable
          sql << " INITIALLY DEFERRED" if deferrable == :initially_deferred
          sql
        end

        def quoted_column_names
          Array(column_names).collect { |name| ::ActiveRecord::Base.connection.quote_column_name(name) }
        end

        def quoted_references_column_names
          Array(references_column_names).collect { |name| ::ActiveRecord::Base.connection.quote_column_name(name) }
        end

        def quoted_references_table_name
          ::ActiveRecord::Base.connection.quote_table_name(references_table_name)
        end

        def unquote(names)
          if names.is_a?(Array)
            names.collect { |name| __unquote(name) }
          else
            __unquote(names)
          end
        end

        def __unquote(value)
          value.to_s.sub(/^["`](.*)["`]$/, '\1')
        end

        def self.default_name(table_name, column_names)
          "fk_#{fixup_schema_name(table_name)}_#{Array.wrap(column_names).join('_and_')}"
        end

        def self.auto_index_name(table_name, column_name)
          "fk__#{fixup_schema_name(table_name)}_#{Array.wrap(column_name).join('_and_')}"
        end

        def self.fixup_schema_name(table_name)
          # replace . with _
          table_name.to_s.gsub(/[.]/, '_')
        end

        def ==(other) # note equality test ignores :name and options
          [:table_name,
           :column_names,
           :references_table_name,
           :references_column_names
           ].all? { |attr| self.send(attr) == other.send(attr) }
        end
      end
    end
  end
end
