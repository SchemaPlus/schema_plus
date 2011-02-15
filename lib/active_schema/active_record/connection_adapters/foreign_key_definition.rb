module ActiveSchema
  module ActiveRecord
    module ConnectionAdapters
      class ForeignKeyDefinition < Struct.new(:name, :table_name, :column_names, :references_table_name, :references_column_names, :on_update, :on_delete, :deferrable)
        ACTIONS = { :cascade => "CASCADE", :restrict => "RESTRICT", :set_null => "SET NULL", :set_default => "SET DEFAULT", :no_action => "NO ACTION" }.freeze

        def initialize(name, table_name, column_names, references_table_name, references_column_names, on_update = nil, on_delete = nil, deferrable = nil)
          super(name, unquote(table_name), unquote(column_names), unquote(references_table_name), unquote(references_column_names), on_update, on_delete, deferrable)
        end

        # Dumps a definition of foreign key.
        # Must be invoked inside create_table block.
        #
        # It was introduced to satisfy sqlite which requires foreign key definitions
        # to be declared when creating a table. That approach is fine for MySQL and
        # PostgreSQL too.
        def to_table_dump
          dump = "  t.foreign_key"
          add_dump_body!(dump)
        end

        # Dumps a definitions of foreign key using generic <tt>add_foreign_key</tt>
        # method.
        #
        # Note that method won't work for sqlite which requires foreign key
        # definitions to be declared inside create_table block
        def to_inline_dump
          dump = "add_foreign_key #{table_name.inspect}"
          add_dump_body!(dump)
        end

        alias :to_dump :to_table_dump

        def to_sql
          sql = name ? "CONSTRAINT #{name} " : ""
          sql << "FOREIGN KEY (#{quoted_column_names.join(", ")}) REFERENCES #{quoted_references_table_name} (#{quoted_references_column_names.join(", ")})"
          sql << " ON UPDATE #{ACTIONS[on_update]}" if on_update
          sql << " ON DELETE #{ACTIONS[on_delete]}" if on_delete
          sql << " DEFERRABLE" if deferrable
          sql
        end

        alias :to_s :to_sql

        def add_dump_body!(dump)
          dump << " [#{Array(column_names).collect{ |name| name.inspect }.join(', ')}]"
          dump << ", #{references_table_name.inspect}, [#{Array(references_column_names).collect{ |name| name.inspect }.join(', ')}]"
          dump << ", :on_update => :#{on_update}" if on_update
          dump << ", :on_delete => :#{on_delete}" if on_delete
          dump << ", :deferrable => #{deferrable}" if deferrable
          dump << ", :name => #{name.inspect}" if name
          dump
        end

        def quoted_column_names
          Array(column_names).collect { |name| ::ActiveRecord::Base.connection.quote_column_name(name) }
        end

        def quoted_references_column_names
          Array(references_column_names).collect { |name| ::ActiveRecord::Base.connection.quote_column_name(name) }
        end

        def quoted_table_name
          ::ActiveRecord::Base.connection.quote_table_name(table_name)
        end
        
        def quoted_references_table_name
          ::ActiveRecord::Base.connection.quote_table_name(references_table_name)
        end

        def quote(name)
          ::ActiveRecord::Base.connection.quote(name)
        end

        def unquote(names)
          if names.is_a?(Array)
            names.collect { |name| __unqoute(name) }
          else
            __unqoute(names)
          end
        end

        def __unqoute(value)
          value.to_s.sub(/^["`](.*)["`]$/, '\1')
        end

      end
    end
  end
end
