require 'schema_monkey'

module SchemaDefaultExpr
  module ActiveRecord
    module ConnectionAdapters

      module AbstractAdapter
        def self.included(base) #:nodoc:
          SchemaMonkey::Middleware::AddColumnOptions.insert(0, AddColumnOptions)
        end

        class AddColumnOptions < ::SchemaMonkey::Middleware::Base
          def call(env)
            if env.options_include_default?
              env.options = options = env.options.dup
              default = options[:default]

              if default.is_a? Hash and [[:expr], [:value]].include?(default.keys)
                value = default[:value]
                expr = env.adapter.sql_for_function(default[:expr]) || default[:expr] if default[:expr]
              else
                value = default
                expr = env.adapter.sql_for_function(default)
              end

              if expr
                raise ArgumentError, "Invalid default expression" unless env.adapter.default_expr_valid?(expr)
                env.sql << " DEFAULT #{expr}"
                # must explicitly check for :null to allow change_column to work on migrations
                if options[:null] == false
                  env.sql << " NOT NULL"
                end
                options.delete(:default)
                options.delete(:null)
              else
                options[:default] = value
              end
            end
            @app.call env
          end

          #####################################################################
          #
          # The functions below here are abstract; each subclass should
          # define them all. Defining them here only for reference.

          # (abstract) Return true if the passed expression can be used as a column
          # default value.  (For most databases the specific expression
          # doesn't matter, and the adapter's function would return a
          # constant true if default expressions are supported or false if
          # they're not.)
          def default_expr_valid?(expr) raise "Internal Error: Connection adapter didn't override abstract function"; end

          # (abstract) Return SQL definition for a given canonical function_name symbol.
          # Currently, the only function to support is :now, which should
          # return a DATETIME object for the current time.
          def sql_for_function(function_name) raise "Internal Error: Connection adapter didn't override abstract function"; end
        end
      end


      module PostgresqlAdapter
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

      module MysqlAdapter
        def default_expr_valid?(expr)
          false # only the TIMESTAMP column accepts SQL column defaults and rails uses DATETIME
        end

        def sql_for_function(function)
          case function
          when :now then 'CURRENT_TIMESTAMP'
          end
        end
      end

      module Sqlite3Adapter
        def default_expr_valid?(expr)
          true # arbitrary sql is okay
        end

        def sql_for_function(function)
          case function
          when :now
            "(DATETIME('now'))"
          end
        end
      end
    end
  end

  class DumpDefaultExpressions < SchemaMonkey::Middleware::Base
    def call(env)
      @app.call env
      env.connection.columns(env.table.name).each do |column|
        if !column.default_function.nil?
          if col = env.table.columns.find{|col| col.name == column.name}
            options = "default: { expr: #{column.default_function.inspect} }"
            options += ", #{col.options}" unless col.options.blank?
            col.options = options
          end
        end
      end
    end
  end

  def self.insert
    SchemaMonkey::Middleware::Dumper::Table.use DumpDefaultExpressions
  end

end

SchemaMonkey.register(SchemaDefaultExpr)
