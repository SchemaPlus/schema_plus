module RedHillConsulting::Core::ActiveRecord::ConnectionAdapters
  # MySQL4-specific behaviors
  module Mysql4Adapter
    def reverse_foreign_keys(table_name, name = nil)
      tables = execute("SHOW TABLES")

      foreign_keys = []
      
      tables.each do |table|
        results = execute("SHOW CREATE TABLE #{table}")
        results.each do |row|
          row[1].lines.each do |line|
            if line =~ /^  CONSTRAINT [`"](.+?)[`"] FOREIGN KEY \([`"](.+?)[`"]\) REFERENCES [`"](.+?)[`"] \((.+?)\)( ON DELETE (.+?))?( ON UPDATE (.+?))?,?$/
              name = $1
              column_names = $2
              references_table_name = $3
              references_column_names = $4
              on_update = $8
              on_delete = $6
              on_update = on_update.downcase.gsub(' ', '_').to_sym if on_update
              on_delete = on_delete.downcase.gsub(' ', '_').to_sym if on_delete

              if references_table_name == table_name
                foreign_keys << ForeignKeyDefinition.new(name,
                                               table, column_names.gsub('`', '').split(', '),
                                               references_table_name, references_column_names.gsub('`', '').split(', '),
                                               on_update, on_delete)
              end
            end
          end
        end
      end

      foreign_keys
    end
  end
end
