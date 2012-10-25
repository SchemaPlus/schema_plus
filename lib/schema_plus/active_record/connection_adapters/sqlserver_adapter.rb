module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters
      module SqlserverAdapter
        def foreign_key_definition_class
          ForeignKeyDefinition
        end

        def indexes (table_name, name = nil) #:nodoc:
          super.each do |index|
            index.unique = true if index.unique
          end
        end

        def create_view (view_name, definition, options={}) #:nodoc:
          quoted_name = quote_table_name(view_name)

          execute "IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS
            WHERE TABLE_NAME = '#{view_name}') DROP VIEW #{quoted_name}" if options[:force]

          execute "CREATE VIEW #{quoted_name} AS #{definition}"
        end

        def views (name = nil)
          super()
        end

        def view_definition (view_name, name = nil)
          if view_info = view_information(view_name)
            view_info[:VIEW_DEFINITION].gsub(/^CREATE +VIEW +(.+) +AS +/i, "")
          end
        end

        def foreign_keys (table_name, name = nil)
          load_foreign_keys(table_name, false, name)
        end

        def reverse_foreign_keys (table_name, name = nil)
          load_foreign_keys(table_name, true, name)
        end

        def default_expr_valid? (expr)
          true # constant expressions are allowed
        end

        def sql_for_function (function_name)
          "GETDATE()" if function_name == :now
        end

        class ForeignKeyDefinition < SchemaPlus::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition
          def initialize(name, table_name, column_names, references_table_name, references_column_names, on_update = nil, on_delete = nil, deferrable = nil)
            error :on_update if on_update == :restrict
            error :on_delete if on_delete == :restrict
            super
          end

        private

          def error (action)
            action = action.to_s.gsub(/_/, " ").upcase
            raise NotImplementedError, "SQL Server does not support #{action} RESTRICT"
          end
        end

      private
        COLUMN_NAMES = "column_names"
        REFERENCES_COLUMN_NAMES = "references_column_names"

        def load_foreign_keys (table_name, reverse, name = nil)
          table = reverse ? "KCU_REF" : "KCU_FK"

          query = <<-SQL
            SELECT
              KCU_FK.CONSTRAINT_NAME AS name,
              KCU_FK.TABLE_NAME AS table_name,
              KCU_FK.COLUMN_NAME AS #{COLUMN_NAMES},
              KCU_REF.TABLE_NAME AS references_table_name,
              KCU_REF.COLUMN_NAME AS #{REFERENCES_COLUMN_NAMES},
              RC.UPDATE_RULE as on_update,
              RC.DELETE_RULE as on_delete,
              null as deferrable
            FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS AS RC

            LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU_FK
              ON KCU_FK.CONSTRAINT_CATALOG = RC.CONSTRAINT_CATALOG
              AND KCU_FK.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA
              AND KCU_FK.CONSTRAINT_NAME = RC.CONSTRAINT_NAME

            LEFT JOIN (
              SELECT
                CONSTRAINT_CATALOG,
                CONSTRAINT_SCHEMA,
                CONSTRAINT_NAME,
                TABLE_CATALOG,
                TABLE_SCHEMA,
                TABLE_NAME,
                COLUMN_NAME,
                ORDINAL_POSITION
              FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
              UNION
              SELECT
                DB_NAME() AS CONSTRAINT_CATALOG,
                SCHEMA_NAME(FK.schema_id) as CONSTRAINT_SCHEMA,
                IX.name AS CONSTRAINT_NAME,
                DB_NAME() AS TABLE_CATALOG,
                SCHEMA_NAME(T.schema_id) AS TABLE_SCHEMA,
                T.name AS TABLE_NAME,
                C.name AS COLUMN_NAME,
                IXC.key_ordinal AS ORDINAL_POSITION
              FROM sys.indexes IX

              JOIN sys.tables T
              ON T.object_id = IX.object_id

              JOIN sys.index_columns IXC
              ON IXC.index_id = IX.index_id
              AND IXC.object_id = IX.object_id

              JOIN sys.foreign_keys FK
              ON FK.referenced_object_id = IX.object_id
              AND FK.key_index_id = IXC.column_id

              JOIN sys.columns C
              ON C.column_id = IXC.column_id
              AND C.object_id = IX.object_id

              WHERE IX.is_unique = 1
              AND IX.is_unique_constraint = 0 AND
              IX.ignore_dup_key = 0
            ) AS KCU_REF
              ON KCU_REF.CONSTRAINT_CATALOG = RC.UNIQUE_CONSTRAINT_CATALOG
              AND KCU_REF.CONSTRAINT_SCHEMA = RC.UNIQUE_CONSTRAINT_SCHEMA
              AND KCU_REF.CONSTRAINT_NAME = RC.UNIQUE_CONSTRAINT_NAME
              AND KCU_REF.ORDINAL_POSITION = KCU_FK.ORDINAL_POSITION

            WHERE #{table}.TABLE_NAME = '#{table_name}'
            ORDER BY name, table_name, references_table_name
          SQL

          foreign_keys = []
          result = raw_select(query, name)

          result.each do |row|
            last_foreign_key = foreign_keys.last
            raw = RawForeignKey.new(*row.values)

            if raw == last_foreign_key
              last_foreign_key.column_names << row[COLUMN_NAMES]
              last_foreign_key.references_table_name << row[REFERENCES_COLUMN_NAMES]
            else
              foreign_keys << raw.to_foreign_key
            end
          end

          foreign_keys
        end

        def foreign_keys_equal? (a, b)
          a.name == b.name &&
            a.table_name == b.table_name &&
            a.references_table_name == b.references_table_name
        end

        RawForeignKey = Struct.new(
          :name, :table_name, :column_names, :references_table_name,
          :references_column_names, :on_update, :on_delete, :deferrable) do

          def initialize (*args)
            members.each_with_index do |member, i|
              send(:"#{member}=", args[i])
            end
          end

          def on_update= (value)
            self[:on_update] = action(value)
          end

          def on_delete= (value)
            self[:on_delete] = action(value)
          end

          def column_names= (value)
            value = value.is_a?(Array) ? value : [value]
            self[:column_names] = value
          end

          def references_column_names= (value)
            value = value.is_a?(Array) ? value : [value]
            self[:references_column_names] = value
          end

          def == (rhs)
            return false if rhs.nil?

            name == rhs.name &&
              table_name == rhs.table_name &&
              references_table_name == rhs.references_table_name
          end

          def to_foreign_key
            ForeignKeyDefinition.new(*values)
          end

          def coerce (other)
            return self, other
          end

        private

          def action (value)
            ForeignKeyDefinition::ACTIONS_REVERSED[value]
          end
        end
      end
    end
  end
end