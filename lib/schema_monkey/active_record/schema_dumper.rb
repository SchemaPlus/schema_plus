require 'ostruct'
require 'tsort'

module SchemaMonkey
  module ActiveRecord
    module SchemaDumper

      class Dump
        include TSort

        attr_reader :extensions, :tables, :dependencies, :data
        attr_accessor :foreign_keys, :trailer

        def initialize(dumper)
          @dumper = dumper
          @dependencies = Hash.new { |h, k| h[k] = [] }
          @extensions = []
          @tables = {}
          @foreign_keys = []
          @data = OpenStruct.new # a place for middleware to leave data
        end

        def depends(tablename, dependents)
          @tables[tablename] ||= false # placeholder for dependencies applied before defining the table
          @dependencies[tablename] += Array.wrap(dependents)
        end

        def assemble(stream)
          stream.puts @extensions.join("\n") if extensions.any?
          assemble_tables(stream)
          foreign_keys.each do |statement|
            stream.puts "  #{statement}"
          end
          stream.puts @trailer
        end

        def assemble_tables(stream)
          tsort().each do |table|
            @tables[table].assemble(stream) if @tables[table]
          end
        end

        def tsort_each_node(&block)
          @tables.keys.sort.each(&block)
        end

        def tsort_each_child(tablename, &block)
          @dependencies[tablename].sort.uniq.reject{|t| @dumper.ignored? t}.each(&block)
        end

        class Table < KeyStruct[:name, :pname, :options, :columns, statements: [], trailer: []]

          def assemble(stream)
            stream.write "  create_table #{pname.inspect}"
            stream.write ", #{options}" unless options.blank?
            stream.puts " do |t|"
            typelen = @columns.map{|col| col.type.length}.max
            namelen = @columns.map{|col| col.name.length}.max
            @columns.each do |column|
              stream.write "    "
              column.assemble(stream, typelen, namelen)
              stream.puts ""
            end
            statements.each do |statement|
              stream.puts "    #{statement}"
            end
            stream.puts "  end"
            trailer.each do |statement|
              stream.puts "  #{statement}"
            end
            stream.puts ""
          end

          class Column < KeyStruct[:name, :type, :options]

            def assemble(stream, typelen, namelen)
              stream.write "t.%-#{typelen}s " % type
              if options.blank?
                stream.write name.inspect
              else
                stream.write "%-#{namelen+3}s %s" % ["#{name.inspect},", options]
              end
            end
          end
        end
      end

      def self.included(base)
        base.class_eval do
          alias_method_chain :dump, :schema_monkey
          alias_method_chain :extensions, :schema_monkey
          alias_method_chain :tables, :schema_monkey
          alias_method_chain :table, :schema_monkey
          alias_method_chain :foreign_keys, :schema_monkey
          alias_method_chain :trailer, :schema_monkey
          public :ignored?
        end
        Middleware::Dumper::Extensions.use Extensions
        Middleware::Dumper::Tables.use Tables
        Middleware::Dumper::Table.use Table
      end

      def dump_with_schema_monkey(stream)
        @dump = Dump.new(self)
        dump_without_schema_monkey(stream)
        @dump.assemble(stream)
      end

      def foreign_keys_with_schema_monkey(table, _)
        stream = StringIO.new
        foreign_keys_without_schema_monkey(table, stream)
        @dump.foreign_keys += stream.string.split("\n").map(&:strip)
      end

      def trailer_with_schema_monkey(_)
        stream = StringIO.new
        trailer_without_schema_monkey(stream)
        @dump.trailer = stream.string
      end

      class Extensions < Middleware::Base
        def call(env)
          stream = StringIO.new
          env.dumper.send :extensions_without_schema_monkey, stream
          env.extensions << stream.string unless stream.string.blank?
          @app.call env
        end
      end

      def extensions_with_schema_monkey(_)
        Middleware::Dumper::Extensions.call Middleware::Dumper::Extensions::Env.new(dumper: self, connection: @connection, extensions: @dump.extensions)
      end

      class Tables < Middleware::Base
        def call(env)
          env.dumper.send :tables_without_schema_monkey, nil
          @app.call env
        end
      end

      def tables_with_schema_monkey(_)
        Middleware::Dumper::Tables.call Middleware::Dumper::Tables::Env.new(dumper: self, connection: @connection, dump: @dump)
      end

      class Table < Middleware::Base
        def call(env)
          stream = StringIO.new
          env.dumper.send :table_without_schema_monkey, env.table.name, stream
          m = stream.string.match %r{
            \A \s*
            create_table \s*
            [:'"](?<name>[^'"\s]+)['"]? \s*
            ,? \s*
            (?<options>.*) \s+
            do \s* \|t\| \s* $
            (?<columns>.*)
            ^\s*end\s*$
            (?<trailer>.*)
            \Z
          }xm
          env.table.pname = m[:name]
          env.table.options = m[:options].strip
          env.table.trailer = m[:trailer].split("\n").map(&:strip).reject{|s| s.blank?}
          env.table.columns = m[:columns].strip.split("\n").map { |col|
            m = col.strip.match %r{
              ^
              t\.(?<type>\S+) \s*
              [:'"](?<name>[^"\s]+)[,"]? \s*
              ,? \s*
              (?<options>.*)
              $
            }x
            Dump::Table::Column.new(name: m[:name], type: m[:type], options: m[:options])
          }
          @app.call env
        end
      end

      def table_with_schema_monkey(table, _)
        Middleware::Dumper::Table.call Middleware::Dumper::Table::Env.new(dumper: self, connection: @connection, dump: @dump, table: @dump.tables[table] = Dump::Table.new(name: table))
      end

    end
  end
end
