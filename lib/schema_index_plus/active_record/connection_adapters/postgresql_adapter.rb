module SchemaIndexPlus
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter

        def supports_partial_indexes? #:nodoc:
          true
        end

        
        # SchemaPlus provides the following extra options for PostgreSQL
        # indexes:
        # * +:conditions+ - SQL conditions for the WHERE clause of the index
        # * +:expression+ - SQL expression to index.  column_name can be nil or ommitted, in which case :name must be provided
        # * +:kind+ - index method for Postgresql to use
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
        def add_index_plus(table_name, column_names, options = {})
          if column_names.empty?
            raise ArgumentError, "No columns and :expression missing from options - cannot create index" unless options[:expression]
            raise ArgumentError, "Index name not given. Pass :name option" unless options[:name]
          end

          index_type = options[:unique] ? "UNIQUE" : ""
          index_name = options[:name] || index_name(table_name, column_names)
          conditions = options[:conditions]
          kind       = options[:kind]
          operator_classes = options[:operator_class]
          if operator_classes and not operator_classes.is_a? Hash
            operator_classes = Hash[column_names.map {|name| [name, operator_classes]}]
          end

          if expression = options[:expression] then
            raise ArgumentError, "Cannot specify :case_sensitive => false with an expression.  Use LOWER(column_name)" if options[:case_sensitive] == false
            # Wrap expression in parentheses if necessary
            expression = "(#{expression})" if expression !~ /(using|with|tablespace|where)/i
            expression = "USING #{kind} #{expression}" if kind
            expression = "#{expression} WHERE #{conditions}" if conditions

            sql = "CREATE #{index_type} INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} #{expression}"
          else
            option_strings = Hash[column_names.map {|name| [name, '']}]
            (operator_classes||{}).stringify_keys.each do |column, opclass|
              option_strings[column] += " #{opclass}" if opclass
            end
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
        end
        
        # This method entirely duplicated from AR's postgresql_adapter.c,
        # but includes the extra bit to determine the column name for a
        # case-insensitive index.  (Haven't come up with any clever way to
        # only code up the case-insensitive column name bit here and
        # otherwise use the existing method.)
        def indexes(table_name, name = nil) #:nodoc:
          result = query(<<-SQL, name)

           SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid,
                  m.amname, pg_get_expr(d.indpred, t.oid) as conditions, pg_get_expr(d.indexprs, t.oid) as expression,
                  d.indclass
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

          result.map do |(index_name, is_unique, indkey, inddef, oid, kind, conditions, expression, indclass)|
            unique = (is_unique == 't' || is_unique == true) # The test against true is for JDBC which is returning a boolean and not a String.
            index_keys = indkey.split(" ")
            opclasses = indclass.split(" ")

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

            opclass_name  = {}
            rows = query(<<-SQL, "Op classes for index #{index_name} on #{table_name}")
              SELECT oid, opcname FROM pg_opclass
              WHERE (NOT opcdefault) AND oid IN (#{opclasses.join(',')})
            SQL
            rows.each do |oid, opcname|
              opclass_name[oid.to_s] = opcname
            end
            operator_classes = {}
            index_keys.zip(opclasses).each do |index_key, opclass|
              operator_classes[columns[index_key]] = opclass_name[opclass]
            end
            operator_classes.delete_if{|k,v| v.nil?}

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
                                                                    :operator_classes => operator_classes,
                                                                    :expression => expression)
          end
        end
      end
    end
  end
end

