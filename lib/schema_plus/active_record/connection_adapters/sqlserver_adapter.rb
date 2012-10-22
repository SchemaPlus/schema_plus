module SchemaPlus
  module ActiveRecord
    module ConnectionAdapters
      module SqlserverAdapter
        # (abstract) Returns the names of all views, as an array of strings
        def views (name = nil) raise "Internal Error: Connection adapter didn't override abstract function"; [] end

        # (abstract) Returns the SQL definition of a given view.  This is
        # the literal SQL would come after 'CREATVE VIEW viewname AS ' in
        # the SQL statement to create a view.
        def view_definition (view_name, name = nil) raise "Internal Error: Connection adapter didn't override abstract function"; end

        # (abstract) Return the ForeignKeyDefinition objects for foreign key
        # constraints defined on this table
        def foreign_keys (table_name, name = nil)
          load_foreign_keys table_name, false, name
        end

        # (abstract) Return the ForeignKeyDefinition objects for foreign key
        # constraints defined on other tables that reference this table
        def reverse_foreign_keys (table_name, name = nil)
          load_foreign_keys table_name, true, name
        end

        # (abstract) Return true if the passed expression can be used as a column
        # default value.  (For most databases the specific expression
        # doesn't matter, and the adapter's function would return a
        # constant true if default expressions are supported or false if
        # they're not.)
        def default_expr_valid? (expr) raise "Internal Error: Connection adapter didn't override abstract function"; end

        # (abstract) Return SQL definition for a given canonical function_name symbol.
        # Currently, the only function to support is :now, which should
        # return a DATETIME object for the current time.
        def sql_for_function (function_name) raise "Internal Error: Connection adapter didn't override abstract function"; end

      private

        def load_foreign_keys (table_name, reverse, name = nil)
          table = reverse ? "KCU_REF" : "KCU_FK"

          result = query(<<-SQL, name)
            SELECT  
              KCU_FK.CONSTRAINT_NAME AS name,
              KCU_FK.TABLE_NAME AS table_name,
              KCU_FK.COLUMN_NAME AS column_names,
              KCU_REF.TABLE_NAME AS references_table_name,
              KCU_REF.COLUMN_NAME AS references_column_names,
              RC.UPDATE_RULE as on_update,
              RC.DELETE_RULE as on_delete,
              TC.IS_DEFERRABLE as deferrable
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

            where #{table}.TABLE_NAME = '#{table_name}'
          SQL

          result
        end
      end
    end
  end
end