require 'active_record/connection_adapters/abstract/schema_definitions'

module SchemaPlus::ForeignKeys
  module ActiveRecord
    module ConnectionAdapters
      # Instances of this class are returned by the queries ActiveRecord::Base#foreign_keys and ActiveRecord::Base#reverse_foreign_keys (via AbstractAdapter#foreign_keys and AbstractAdapter#reverse_foreign_keys)
      #
      # The on_update and on_delete attributes can take on the following values:
      #   :cascade
      #   :restrict
      #   :nullify
      #   :set_default
      #   :no_action
      #
      # The deferrable attribute can take on the following values:
      #   true
      #   :initially_deferred
      module ForeignKeyDefinition

        def column_names
          ActiveSupport::Deprecation.warn "ForeignKeyDefinition#column_names is deprecated, use Array.wrap(column)"
          Array.wrap(column)
        end

        def references_column_names
          ActiveSupport::Deprecation.warn "ForeignKeyDefinition#references_column_names is deprecated, use Array.wrap(primary_key)"
          Array.wrap(primary_key)
        end

        def references_table_name
          ActiveSupport::Deprecation.warn "ForeignKeyDefinition#references_table_name is deprecated, use #to_table"
          to_table
        end

        def table_name
          ActiveSupport::Deprecation.warn "ForeignKeyDefinition#table_name is deprecated, use #from_table"
          from_table
        end

        ACTIONS = { :cascade => "CASCADE", :restrict => "RESTRICT", :nullify => "SET NULL", :set_default => "SET DEFAULT", :no_action => "NO ACTION" }.freeze
        ACTION_LOOKUP = ACTIONS.invert.freeze

        def initialize(from_table, to_table, options={})
          [:on_update, :on_delete].each do |key|
            if options[key] == :set_null
              ActiveSupport::Deprecation.warn ":set_null value for #{key} is deprecated.  use :nullify instead"
              options[key] = :nullify
            end
          end

          super from_table, to_table, options

          if column.is_a?(Array) and column.length == 1
            options[:column] = column[0]
          end
          if primary_key.is_a?(Array) and primary_key.length == 1
            options[:primary_key] = primary_key[0]
          end

          ACTIONS.has_key?(on_update) or raise(ArgumentError, "invalid :on_update action: #{on_update.inspect}") if on_update
          ACTIONS.has_key?(on_delete) or raise(ArgumentError, "invalid :on_delete action: #{on_delete.inspect}") if on_delete
          if ::ActiveRecord::Base.connection.adapter_name =~ /^mysql/i
            raise(NotImplementedError, "MySQL does not support ON UPDATE SET DEFAULT") if on_update == :set_default
            raise(NotImplementedError, "MySQL does not support ON DELETE SET DEFAULT") if on_delete == :set_default
          end
        end

        # Truthy if the constraint is deferrable
        def deferrable
          options[:deferrable]
        end

        # Dumps a definition of foreign key.
        def to_dump(column: nil, inline: nil)
          dump = case
                 when column then "foreign_key: {references:"
                 when inline then "t.foreign_key"
                 else "add_foreign_key #{from_table.inspect},"
                 end
          dump << " #{to_table.inspect}"

          val_or_array = -> val { val.is_a?(Array) ? "[#{val.map(&:inspect).join(', ')}]" : val.inspect }

          dump << ", column: #{val_or_array.call self.column}" unless column
          dump << ", primary_key: #{val_or_array.call self.column}" if custom_primary_key?
          dump << ", name: #{name.inspect}" if name
          dump << ", on_update: #{on_update.inspect}" if on_update
          dump << ", on_delete: #{on_delete.inspect}" if on_delete
          dump << ", deferrable: #{deferrable.inspect}" if deferrable
          dump << "}" if column
          dump
        end

        def to_sql
          sql = name ? "CONSTRAINT #{name} " : ""
          sql << "FOREIGN KEY (#{quoted_column_names.join(", ")}) REFERENCES #{quoted_to_table} (#{quoted_primary_keys.join(", ")})"
          sql << " ON UPDATE #{ACTIONS[on_update]}" if on_update
          sql << " ON DELETE #{ACTIONS[on_delete]}" if on_delete
          sql << " DEFERRABLE" if deferrable
          sql << " INITIALLY DEFERRED" if deferrable == :initially_deferred
          sql
        end

        def quoted_column_names
          Array(column).map { |name| ::ActiveRecord::Base.connection.quote_column_name(name) }
        end

        def quoted_primary_keys
          Array(primary_key).map { |name| ::ActiveRecord::Base.connection.quote_column_name(name) }
        end

        def quoted_to_table
          ::ActiveRecord::Base.connection.quote_table_name(to_table)
        end

        def self.default_name(from_table, column)
          "fk_#{fixup_schema_name(from_table)}_#{Array.wrap(column).join('_and_')}"
        end

        def self.auto_index_name(from_table, column_name)
          "fk__#{fixup_schema_name(from_table)}_#{Array.wrap(column_name).join('_and_')}"
        end

        def self.fixup_schema_name(table_name)
          # replace . with _
          table_name.to_s.gsub(/[.]/, '_')
        end

        def match(test)
          return false unless from_table == test.from_table
          [:to_table, :column].reject{ |attr| test.send(attr).blank? }.all? { |attr|
            test.send(attr).to_s == self.send(attr).to_s
          }
        end
      end
    end
  end
end
