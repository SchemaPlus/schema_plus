module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters
      # PostgreSQL-specific extensions to column definitions in a table.
      module PostgreSQLColumn
        # Extracts the value from a PostgreSQL column default definition.
        def self.included(base) #:nodoc:
          base.extend ClassMethods
          if defined?(JRUBY_VERSION)
            base.alias_method_chain :default_value, :schema_plus
          else
            base.class_eval do
              class << self
                alias_method_chain :extract_value_from_default, :schema_plus
              end
            end
          end
        end

        def initialize(name, default, sql_type = nil, null = true)
          if default.is_a? Hash
            if default[:expr]
              @default_expr = default[:expr]
            end
            default = nil
          end
          super(name, default, sql_type, null)
        end

        def default_value_with_schema_plus(default)
          value = default_value_without_schema_plus(default)
          self.class.convert_default_value(default, value)
        end

        module ClassMethods
          def extract_value_from_default_with_schema_plus(default)
            value = extract_value_from_default_without_schema_plus(default)
            convert_default_value(default, value)
          end

          # in some cases (e.g. if change_column_default(table, column,
          # nil) is used), postgresql will return NULL::xxxxx (rather
          # than nil) for a null default -- make sure we treat it as nil,
          # not as a function.
          def convert_default_value(default, value)
            default = nil if value.nil? && default =~ /\ANULL::(?:character varying|bpchar|text)\z/m

            if value.nil? && !default.nil?
              value = { :expr => default }
            end
            value
          end
        end
      end

      # The Postgresql adapter implements the SchemaPlus extensions and
      # enhancements
      module PostgresqlAdapter

        def self.included(base) #:nodoc:
          base.class_eval do
            if ::ActiveRecord::VERSION::MAJOR.to_i < 4 && !defined?(JRUBY_VERSION)
              remove_method :indexes
            end
            alias_method_chain :rename_table, :schema_plus
            alias_method_chain :exec_cache, :schema_plus unless defined?(JRUBY_VERSION)
          end
          ::ActiveRecord::ConnectionAdapters::PostgreSQLColumn.send(:include, PostgreSQLColumn) unless ::ActiveRecord::ConnectionAdapters::PostgreSQLColumn.include?(PostgreSQLColumn)
        end

        # SchemaPlus provides the following extra options for Postgres
        # indexes:
        # * +:conditions+ - SQL conditions for the WHERE clause of the index
        # * +:expression+ - SQL expression to index.  column_name can be nil or ommitted, in which case :name must be provided
        # * +:kind+ - index method for Postgresql to use
        # * +:case_sensitive - setting to +false+ is a shorthand for :expression => 'LOWER(column_name)'
        #
        # The <tt>:case_sensitive => false</tt> option ties in with Rails built-in support for case-insensitive searching:
        #    validates_uniqueness_of :name, :case_sensitive => false
        #
        # Since since <tt>:case_sensitive => false</tt> is implemented by
        # using <tt>:expression</tt>, this raises an ArgumentError if both
        # are specified simultaneously.
        #
        def add_index(table_name, column_name, options = {})
          options = {} if options.nil?  # some callers explicitly pass options=nil
          column_name, options = [], column_name if column_name.is_a?(Hash)
          column_names = Array(column_name).compact
          if column_names.empty?
            raise ArgumentError, "No columns and :expression missing from options - cannot create index" unless options[:expression]
            raise ArgumentError, "Index name not given. Pass :name option" unless options[:name]
          end

          index_type = options[:unique] ? "UNIQUE" : ""
          index_name = options[:name] || index_name(table_name, column_names)
          conditions = options[:conditions]
          kind       = options[:kind]

          if expression = options[:expression] then
            raise ArgumentError, "Cannot specify :case_sensitive => false with an expression.  Use LOWER(column_name)" if options[:case_sensitive] == false
            # Wrap expression in parentheses if necessary
            expression = "(#{expression})" if expression !~ /(using|with|tablespace|where)/i
            expression = "USING #{kind} #{expression}" if kind
            expression = "#{expression} WHERE #{conditions}" if conditions

            sql = "CREATE #{index_type} INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} #{expression}"
          else
            option_strings = Hash[column_names.map {|name| [name, '']}]
            option_strings = add_index_sort_order(option_strings, column_names, options)

            if options[:case_sensitive] == false
              caseable_columns = columns(table_name).select { |col| [:string, :text].include?(col.type) }.map(&:name)
              quoted_column_names = column_names.map do |col_name|
                (caseable_columns.include?(col_name.to_s) ? "LOWER(#{quote_column_name(col_name)})" : quote_column_name(col_name)) + option_strings[col_name]
              end
            else
              quoted_column_names = column_names.map { |col_name| quote_column_name(col_name) + option_strings[col_name] }
            end

            expression = "(#{quoted_column_names.join(', ')})"
            expression = "USING #{kind} #{expression}" if kind

            sql = "CREATE #{index_type} INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} #{expression}"
            sql += " WHERE (#{ ::ActiveRecord::Base.send(:sanitize_sql, conditions, quote_table_name(table_name)) })" if conditions
          end
          execute sql
        rescue => e
          SchemaStatements.add_index_exception_handler(self, table_name, column_names, options, e)
        end

        def supports_partial_indexes? #:nodoc:
          true
        end

        # This method entirely duplicated from AR's postgresql_adapter.c,
        # but includes the extra bit to determine the column name for a
        # case-insensitive index.  (Haven't come up with any clever way to
        # only code up the case-insensitive column name bit here and
        # otherwise use the existing method.)
        def indexes(table_name, name = nil) #:nodoc:
          result = query(<<-SQL, name)

           SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid,
                  m.amname, pg_get_expr(d.indpred, t.oid) as conditions, pg_get_expr(d.indexprs, t.oid) as expression
           FROM pg_class t
           INNER JOIN pg_index d ON t.oid = d.indrelid
           INNER JOIN pg_class i ON d.indexrelid = i.oid
           INNER JOIN pg_am m ON i.relam = m.oid
           WHERE i.relkind = 'i'
             AND d.indisprimary = 'f'
             AND t.relname = '#{table_name_without_namespace(table_name)}'
             AND i.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = #{namespace_sql(table_name)} )
          ORDER BY i.relname
          SQL

          result.map do |(index_name, is_unique, indkey, inddef, oid, kind, conditions, expression)|
            unique = (is_unique == 't')
            index_keys = indkey.split(" ")

            rows = query(<<-SQL, "Columns for index #{index_name} on #{table_name}")
              SELECT CAST(a.attnum as VARCHAR), a.attname, t.typname
              FROM pg_attribute a
              INNER JOIN pg_type t ON a.atttypid = t.oid
              WHERE a.attrelid = #{oid}
            SQL
            columns = {}
            types = {}
            rows.each do |num, name, type|
              columns[num] = name
              types[name] = type
            end

            column_names = columns.values_at(*index_keys).compact
            case_sensitive = true

            # extract column names from the expression, for a
            # case-insensitive index.
            # only applies to character, character varying, and text
            if expression
              rexp_lower = %r{\blower\(\(?([^)]+)(\)::text)?\)}
              if expression.match /\A#{rexp_lower}(?:, #{rexp_lower})*\z/
                case_insensitive_columns = expression.scan(rexp_lower).map(&:first).select{|column| %W[char varchar text].include? types[column]}
                if case_insensitive_columns.any?
                  case_sensitive = false
                  column_names = index_keys.map { |index_key|
                    index_key == '0' ? case_insensitive_columns.shift : columns[index_key]
                  }.compact
                end
              end
            end

            # add info on sort order for columns (only desc order is explicitly specified, asc is the default)
            desc_order_columns = inddef.scan(/(\w+) DESC/).flatten
            orders = desc_order_columns.any? ? Hash[column_names.map {|column| [column, desc_order_columns.include?(column) ? :desc : :asc]}] : {}

            ::ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, column_names,
                                                                    :name => index_name,
                                                                    :unique => unique,
                                                                    :orders => orders,
                                                                    :conditions => conditions,
                                                                    :case_sensitive => case_sensitive,
                                                                    :kind => kind.downcase == "btree" ? nil : kind,
                                                                    :expression => expression)
          end
        end

        def query(*args)
          select(*args).map(&:values)
        end if defined?(JRUBY_VERSION)

        def rename_table_with_schema_plus(oldname, newname) #:nodoc:
          rename_table_without_schema_plus(oldname, newname)
          rename_indexes_and_foreign_keys(oldname, newname)
        end

        # Prepass to replace each ActiveRecord::DB_DEFAULT with a literal
        # DEFAULT in the sql string.  (The underlying pg gem provides no
        # way to bind a value that will replace $n with DEFAULT)
        def exec_cache_with_schema_plus(sql, *args)
          name_passed = (2 == args.size)
          binds, name = args.reverse

          if binds.any?{ |col, val| val.equal? ::ActiveRecord::DB_DEFAULT}
            j = 0
            binds.each_with_index do |(col, val), i|
            if val.equal? ::ActiveRecord::DB_DEFAULT
              sql = sql.sub(/\$#{i+1}/, 'DEFAULT')
            else
              sql = sql.sub(/\$#{i+1}/, "$#{j+1}") if i != j
              j += 1
            end
            end
            binds = binds.reject{|col, val| val.equal? ::ActiveRecord::DB_DEFAULT}
          end

          args = name_passed ? [name, binds] : [binds]
          exec_cache_without_schema_plus(sql, *args)
        end

        def foreign_keys(table_name, name = nil) #:nodoc:
          load_foreign_keys(<<-SQL, name)
        SELECT f.conname, pg_get_constraintdef(f.oid), t.relname
          FROM pg_class t, pg_constraint f
         WHERE f.conrelid = t.oid
           AND f.contype = 'f'
           AND t.relname = '#{table_name_without_namespace(table_name)}'
           AND t.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = #{namespace_sql(table_name)} )
          SQL
        end

        def reverse_foreign_keys(table_name, name = nil) #:nodoc:
          load_foreign_keys(<<-SQL, name)
        SELECT f.conname, pg_get_constraintdef(f.oid), t2.relname
          FROM pg_class t, pg_class t2, pg_constraint f
         WHERE f.confrelid = t.oid
           AND f.conrelid = t2.oid
           AND f.contype = 'f'
           AND t.relname = '#{table_name_without_namespace(table_name)}'
           AND t.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = #{namespace_sql(table_name)} )
          SQL
        end

        def views(name = nil) #:nodoc:
          sql = <<-SQL
            SELECT viewname
              FROM pg_views
            WHERE schemaname = ANY (current_schemas(false))
            AND viewname NOT LIKE 'pg\_%'
          SQL
          sql += " AND schemaname != 'postgis'" if adapter_name == 'PostGIS'
          query(sql, name).map { |row| row[0] }
        end

        def view_definition(view_name, name = nil) #:nodoc:
          result = query(<<-SQL, name)
        SELECT pg_get_viewdef(oid)
          FROM pg_class
         WHERE relkind = 'v'
           AND relname = '#{view_name}'
          SQL
          row = result.first
          row.first.chomp(';') unless row.nil?
        end

        private

        def namespace_sql(table_name)
          (table_name.to_s =~ /(.*)[.]/) ?  "'#{$1}'" : "ANY (current_schemas(false))"
        end

        def table_name_without_namespace(table_name)
          table_name.to_s.sub /.*[.]/, ''
        end

        def load_foreign_keys(sql, name = nil) #:nodoc:
          foreign_keys = []

          query(sql, name).each do |row|
            if row[1] =~ /^FOREIGN KEY \((.+?)\) REFERENCES (.+?)\((.+?)\)( ON UPDATE (.+?))?( ON DELETE (.+?))?( (DEFERRABLE|NOT DEFERRABLE)( (INITIALLY DEFERRED|INITIALLY IMMEDIATE))?)?$/
              name = row[0]
              from_table_name = row[2]
              column_names = $1
              references_table_name = $2
              references_column_names = $3
              on_update = $5
              on_delete = $7
              deferrable = $9 == "DEFERRABLE"
              deferrable = :initially_deferred if ($11 == "INITIALLY DEFERRED" )
              on_update = on_update ? on_update.downcase.gsub(' ', '_').to_sym : :no_action
              on_delete = on_delete ? on_delete.downcase.gsub(' ', '_').to_sym : :no_action

              foreign_keys << ForeignKeyDefinition.new(name,
                                                       from_table_name, column_names.split(', '),
                                                       references_table_name.sub(/^"(.*)"$/, '\1'), references_column_names.split(', '),
                                                       on_update, on_delete, deferrable)
            end
          end

          foreign_keys
        end

        module AddColumnOptions
          def default_expr_valid?(expr)
            true # arbitrary sql is okay in PostgreSQL
          end

          def sql_for_function(function)
            case function
              when :now
                "NOW()"
            end
          end
        end
      end
    end
  end
end
