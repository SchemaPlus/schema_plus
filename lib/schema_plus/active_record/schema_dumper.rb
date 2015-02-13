require 'tsort'

module SchemaPlus
  module ActiveRecord

    # SchemaPlus modifies ActiveRecord's schema dumper to include foreign
    # key constraints and views.
    #
    # Additionally, index and foreign key constraint definitions are dumped
    # inline in the create_table block.  (This is done for elegance, but
    # also because Sqlite3 does not allow foreign key constraints to be
    # added to a table after it has been defined.)
    #
    # The tables and views are dumped in alphabetical order, subject to
    # topological sort constraints that a table must be dumped before any
    # view that references it or table that has a foreign key constaint to
    # it.
    #
    module SchemaDumper

      include TSort

      def self.included(base) #:nodoc:
        base.class_eval do
          private
          alias_method_chain :table, :schema_plus
          alias_method_chain :tables, :schema_plus
          alias_method_chain :indexes, :schema_plus
          alias_method_chain :foreign_keys, :schema_plus if private_method_defined? :foreign_keys
        end
      end

      private

      def foreign_keys_with_schema_plus(*)
        # do nothing.  this overrides AR 4.2's foreign key dumping method, which isn't needed
        # because we're dong them inline
      end

      def break_fk_cycles #:nodoc:
        strongly_connected_components.select{|component| component.size > 1}.each do |tables|
          table = tables.sort.last
          backref_fks = @inline_fks[table].select{|fk| tables.include?(fk.references_table_name)}
          @inline_fks[table] -= backref_fks
          @dump_dependencies[table] -= backref_fks.collect(&:references_table_name)
          backref_fks.each do |fk|
            @backref_fks[fk.references_table_name] << fk
          end
        end
      end

      def tables_with_schema_plus(stream) #:nodoc:
        @table_dumps = {}
        @inline_fks = Hash.new{ |h, k| h[k] = [] }
        @backref_fks = Hash.new{ |h, k| h[k] = [] }
        @dump_dependencies = {}

        if @connection.respond_to?(:enums)
          @connection.enums.each do |schema, name, values|
            params = [name.inspect]
            params << values.map(&:inspect).join(', ')
            params << ":schema => #{schema.inspect}" if schema != 'public'

            stream.puts "  create_enum #{params.join(', ')}"
          end
        end

      if "#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}".to_r < "4.2".to_r
        tables_without_schema_plus(nil)
      else
        tables_without_schema_plus(stream)
      end

        @connection.views.each do |view_name|
          next if Array.wrap(::ActiveRecord::SchemaDumper.ignore_tables).any? {|pattern| view_name.match pattern}
          definition = @connection.view_definition(view_name)
          @table_dumps[view_name] = "  create_view #{view_name.inspect}, #{definition.inspect}, :force => true\n"
        end

        re_view_referent = %r{(?:(?i)FROM|JOIN) \S*\b(#{(@table_dumps.keys).join('|')})\b}
        @table_dumps.keys.each do |table|
          if @connection.views.include?(table)
            dependencies = @connection.view_definition(table).scan(re_view_referent).flatten
          else
            @inline_fks[table] = @connection.foreign_keys(table)
            dependencies = @inline_fks[table].collect(&:references_table_name)
          end
          # select against @table_dumps keys to respect filtering based on
          # SchemaDumper.ignore_tables (which was taken into account
          # increate @table_dumps)
          @dump_dependencies[table] = dependencies.sort.uniq.select {|name| @table_dumps.has_key? name}
        end

        # Normally we dump foreign key constraints inline in the table
        # definitions, both for visual cleanliness and because sqlite3
        # doesn't allow foreign key constraints to be added afterwards.
        # But in case there's a cycle in the constraint references, some
        # constraints will need to be broken out then added later.  (Adding
        # constraints later won't work with sqlite3, but that means sqlite3
        # won't let you create cycles in the first place.)
        break_fk_cycles while strongly_connected_components.any?{|component| component.size > 1}

        tsort().each do |table|
          table_dump = @table_dumps[table]
          if i = (table_dump =~ /^\s*[e]nd\s*$/)
            table_dump.insert i, dump_indexes(table) + dump_foreign_keys(@inline_fks[table], :inline => true)
          end
          stream.print table_dump
          stream.puts dump_foreign_keys(@backref_fks[table], :inline => false)+"\n" if @backref_fks[table].any?
        end

      end

      def tsort_each_node(&block) #:nodoc:
        @table_dumps.keys.sort.each(&block)
      end

      def tsort_each_child(table, &block) #:nodoc:
        @dump_dependencies[table].each(&block)
      end

      def table_with_schema_plus(table, ignore) #:nodoc:
        stream = StringIO.new
        table_without_schema_plus(table, stream)
        stream_string = stream.string
        @connection.columns(table).each do |column|
          if "#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}".to_r < "4.2".to_r
            if !column.default_expr.nil?
              stream_string.gsub!("\"#{column.name}\"", "\"#{column.name}\", :default => { :expr => #{column.default_expr.inspect} }")
            end
          else
            if !column.default_function.nil?
              stream_string.gsub!("\"#{column.name}\"", "\"#{column.name}\", :default => { :expr => #{column.default_function.inspect} }")
            end
          end
        end
        @table_dumps[table] = stream_string
      end

      def indexes_with_schema_plus(table, stream) #:nodoc:
        # do nothing.  we've already taken care of indexes as part of
        # dumping the tables
      end

      def dump_indexes(table) #:nodoc:
        @connection.indexes(table).collect{ |index|
          dump = "    t.index"
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
        }.sort.join
      end

      def dump_foreign_keys(foreign_keys, opts={}) #:nodoc:
        foreign_keys.collect{ |foreign_key| "  " + foreign_key.to_dump(:inline => opts[:inline]) }.sort.join
      end
    end
  end
end
