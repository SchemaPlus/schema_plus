module RedHillConsulting::Core::ActiveRecord::ConnectionAdapters
  class ForeignKeyDefinition < Struct.new(:name, :table_name, :column_names, :references_table_name, :references_column_names, :on_update, :on_delete, :deferrable)
    ACTIONS = { :cascade => "CASCADE", :restrict => "RESTRICT", :set_null => "SET NULL", :set_default => "SET DEFAULT", :no_action => "NO ACTION" }.freeze

    def to_dump
      dump = "add_foreign_key"
      dump << " #{table_name.inspect}, [#{Array(column_names).collect{ |name| name.inspect }.join(', ')}]"
      dump << ", #{references_table_name.inspect}, [#{Array(references_column_names).collect{ |name| name.inspect }.join(', ')}]"
      dump << ", :on_update => :#{on_update}" if on_update
      dump << ", :on_delete => :#{on_delete}" if on_delete
      dump << ", :deferrable => #{deferrable}" if deferrable
      dump << ", :name => #{name.inspect}" if name
      dump
    end

    def to_sql
      sql = name ? "CONSTRAINT #{name} " : ""
      sql << "FOREIGN KEY (#{Array(column_names).join(", ")}) REFERENCES #{references_table_name} (#{Array(references_column_names).join(", ")})"
      sql << " ON UPDATE #{ACTIONS[on_update]}" if on_update
      sql << " ON DELETE #{ACTIONS[on_delete]}" if on_delete
      sql << " DEFERRABLE" if deferrable
      sql
    end
    alias :to_s :to_sql
  end
end
