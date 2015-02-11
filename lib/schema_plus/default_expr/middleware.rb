module SchemaPlusDefaultExpr
  module Middleware

    module Sql
      module ColumnOptions

        # Add options for default expressions
        def before(env)
          options = env.options

          return unless (default = options[:default])

          if default.is_a? Hash and [[:expr], [:value]].include?(default.keys)
            value = default[:value]
            expr = env.connection.sql_for_function(default[:expr]) || default[:expr] if default[:expr]
          else
            value = default
            expr = env.connection.sql_for_function(default)
          end

          if expr
            raise ArgumentError, "Invalid default expression" unless env.connection.default_expr_valid?(expr)
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
      end
    end

    module Dumper
      module Table

        # Emit default expression options in dump
        def after(env)
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
    end
  end
end
