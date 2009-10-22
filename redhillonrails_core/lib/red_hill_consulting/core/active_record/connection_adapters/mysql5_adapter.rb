module RedHillConsulting::Core::ActiveRecord::ConnectionAdapters
  # MySQL5-specific behaviors
  module Mysql5Adapter
    def reverse_foreign_keys(table_name, name = nil)
      @@schema ||= nil
      @@schema_version ||= 0
      current_version = ActiveRecord::Migrator.current_version
      if @@schema.nil? || @@schema_version != current_version
        @@schema_version = current_version
        ans = execute(<<-SQL, name)
        SELECT constraint_name, table_name, column_name, referenced_table_name, referenced_column_name
          FROM information_schema.key_column_usage
         WHERE table_schema = SCHEMA()
           AND referenced_table_schema = table_schema
         ORDER BY constraint_name, ordinal_position;
        SQL
        @@schema = []
        ans.each do | row |
          @@schema << [row[0], row[1], row[2], row[3], row[4]]
        end
      end
      results = @@schema
      current_foreign_key = nil
      foreign_keys = []

      results.each do |row|
        next unless table_name.casecmp(row[3]) == 0
        if current_foreign_key != row[0]
          foreign_keys << ForeignKeyDefinition.new(row[0], row[1], [], row[3], [])
          current_foreign_key = row[0]
        end

        foreign_keys.last.column_names << row[2]
        foreign_keys.last.references_column_names << row[4]
      end

      foreign_keys
    end
  end
end