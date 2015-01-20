module SchemaIndexPlus
  module Middleware
    module Postgresql
      def self.insert
        SchemaMonkey::Middleware::Migration::IndexComponentsSql.append DefineExtensions
        SchemaMonkey::Middleware::Query::Indexes.append LookupExtensions
      end

      class DefineExtensions < SchemaMonkey::Middleware::Base
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
          connection = env.connection

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
            option_strings = connection.send :add_index_sort_order, option_strings, column_names, options

            if case_insensitive
              caseable_columns = connection.columns(table_name).select { |col| [:string, :text].include?(col.type) }.map(&:name)
              quoted_column_names = column_names.map do |col_name|
                (caseable_columns.include?(col_name.to_s) ? "LOWER(#{connection.quote_column_name(col_name)})" : connection.quote_column_name(col_name)) + option_strings[col_name]
              end
            else
              quoted_column_names = column_names.map { |col_name| connection.quote_column_name(col_name) + option_strings[col_name] }
            end

            env.sql.columns = quoted_column_names.join(', ')
          end
        end
      end

      class LookupExtensions < SchemaMonkey::Middleware::Base

        def get_opclass_names(env, opclasses)
          @opclass_names ||= {}
          if (missing = opclasses - @opclass_names.keys).any?
            result = env.connection.query(<<-SQL, 'SCHEMA')
              SELECT oid, opcname FROM pg_opclass
              WHERE (NOT opcdefault) AND oid IN (#{opclasses.join(',')})
            SQL
            result.each do |oid, opcname|
              @opclass_names[oid] = opcname
            end
          end
        end

        def call(env)
          # Ideally we'd let AR do its stuff and then add the extras.
          #
          # But one of the extras is expressions.  AR completely strips out
          # indexes with expressions, so to handle them we need to
          # essentially reissue the original query and then duplicate what
          # AR does to process them.  That being the case we may as well
          # just skip AR's implementation and use ours.
          #
          # We could limit that query to just those indexes that have
          # expressions, but we'd still have our code duplicating the AR
          # code.  Plus, our own query can handle operator classess at the
          # same time, but to add operator_classes to AR's definitions we'd
          # still have to issue additional queries.  Plus, using our own
          # query we have the opportunity to handle tables of the form
          # 'namespace.tablename'
          #
          # So, we use our code and DO NOT DO:
          #
          #      continue env
          #
          result = env.connection.query(<<-SQL, 'SCHEMA')

           SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid,
                  m.amname, pg_get_expr(d.indpred, t.oid) as conditions, pg_get_expr(d.indexprs, t.oid) as expression,
                  d.indclass
           FROM pg_class t
           INNER JOIN pg_index d ON t.oid = d.indrelid
           INNER JOIN pg_class i ON d.indexrelid = i.oid
           INNER JOIN pg_am m ON i.relam = m.oid
           WHERE i.relkind = 'i'
             AND d.indisprimary = 'f'
             AND t.relname = '#{table_name_without_namespace(env.table_name)}'
             AND i.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = #{namespace_sql(env.table_name)} )
          ORDER BY i.relname
          SQL

          env.index_definitions += result.map do |(index_name, unique, indkey, inddef, oid, using, conditions, expression, indclass)|
            index_keys = indkey.split(" ")
            opclasses = indclass.split(" ")

            rows = env.connection.query(<<-SQL, 'SCHEMA')
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

              get_opclass_names(env, opclasses)
              operator_classes = Hash[
                index_keys.zip(opclasses).map { |index_key, opclass| [columns[index_key], @opclass_names[opclass]] }
              ]
              operator_classes.delete_if{|k,v| v.nil?}

              # add info on sort order for columns (only desc order is explicitly specified, asc is the default)
              desc_order_columns = inddef.scan(/(\w+) DESC/).flatten
              orders = desc_order_columns.any? ? Hash[column_names.map {|column| [column, desc_order_columns.include?(column) ? :desc : :asc]}] : {}

              ::ActiveRecord::ConnectionAdapters::IndexDefinition.new(env.table_name, column_names,
                                                                      :name => index_name,
                                                                      :unique => (unique == 't'),
                                                                      :orders => orders,
                                                                      :where => conditions,
                                                                      :case_sensitive => case_sensitive,
                                                                      :using => using.downcase == "btree" ? nil : using.to_sym,
                                                                      :operator_classes => operator_classes,
                                                                      :expression => expression)
          end
        end

        def namespace_sql(table_name)
          (table_name.to_s =~ /(.*)[.]/) ?  "'#{$1}'" : "ANY (current_schemas(false))"
        end

        def table_name_without_namespace(table_name)
          table_name.to_s.sub /.*[.]/, ''
        end
      end
    end
  end
end
