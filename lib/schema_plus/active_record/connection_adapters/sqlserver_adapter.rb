module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters
      module SqlserverAdapter
        def foreign_key_definition_class
          ForeignKeyDefinition
        end

        # # (abstract) Returns the names of all views, as an array of strings
        # def views (name = nil) raise "Internal Error: Connection adapter didn't override abstract function"; [] end
        # 
        # # (abstract) Returns the SQL definition of a given view.  This is
        # # the literal SQL would come after 'CREATVE VIEW viewname AS ' in
        # # the SQL statement to create a view.
        # def view_definition (view_name, name = nil) raise "Internal Error: Connection adapter didn't override abstract function"; end

        # (abstract) Return the ForeignKeyDefinition objects for foreign key
        # constraints defined on this table
        def foreign_keys (table_name, name = nil)
          load_foreign_keys(table_name, false, name)
        end

        # (abstract) Return the ForeignKeyDefinition objects for foreign key
        # constraints defined on other tables that reference this table
        def reverse_foreign_keys (table_name, name = nil)
          load_foreign_keys(table_name, true, name)
        end

        # # (abstract) Return true if the passed expression can be used as a column
        # # default value.  (For most databases the specific expression
        # # doesn't matter, and the adapter's function would return a
        # # constant true if default expressions are supported or false if
        # # they're not.)
        # def default_expr_valid? (expr) raise "Internal Error: Connection adapter didn't override abstract function"; end

        # (abstract) Return SQL definition for a given canonical function_name symbol.
        # Currently, the only function to support is :now, which should
        # return a DATETIME object for the current time.
        def sql_for_function (function_name)
          "GETDATE()" if function_name == :now
        end

        class ForeignKeyDefinition < SchemaPlus::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition
          def initialize(name, table_name, column_names, references_table_name, references_column_names, on_update = nil, on_delete = nil, deferrable = nil)
            on_update = sqlserver_action(on_update)
            on_delete = sqlserver_action(on_delete)
            super
          end

        private

          def sqlserver_action (action)
            action == :restrict ? :no_action : action
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
              CASE
                WHEN TC.IS_DEFERRABLE = 'YES' THEN 1
                ELSE NULL
              END as deferrable
            FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS AS RC 

            LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU_FK 
              ON KCU_FK.CONSTRAINT_CATALOG = RC.CONSTRAINT_CATALOG  
              AND KCU_FK.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA 
              AND KCU_FK.CONSTRAINT_NAME = RC.CONSTRAINT_NAME 

            LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU_REF 
              ON KCU_REF.CONSTRAINT_CATALOG = RC.UNIQUE_CONSTRAINT_CATALOG  
              AND KCU_REF.CONSTRAINT_SCHEMA = RC.UNIQUE_CONSTRAINT_SCHEMA 
              AND KCU_REF.CONSTRAINT_NAME = RC.UNIQUE_CONSTRAINT_NAME 
              AND KCU_REF.ORDINAL_POSITION = KCU_FK.ORDINAL_POSITION

            LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
              ON TC.CONSTRAINT_CATALOG = RC.UNIQUE_CONSTRAINT_CATALOG  
              AND TC.CONSTRAINT_SCHEMA = RC.UNIQUE_CONSTRAINT_SCHEMA 
              AND TC.CONSTRAINT_NAME = RC.UNIQUE_CONSTRAINT_NAME

            WHERE #{table}.TABLE_NAME = '#{table_name}'
            ORDER BY name, table_name, references_table_name
          SQL

          foreign_keys = []
          result = exec_query(query, name)

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