module RedHillConsulting::Core::ActiveRecord::ConnectionAdapters
  module PostgresqlAdapter
    def self.included(base)
      base.class_eval do
        alias_method_chain :indexes, :redhillonrails_core
      end
    end

    def set_table_comment(table_name, comment)
      execute "COMMENT ON TABLE #{quote_table_name(table_name)} IS '#{quote_string(comment)}'"
    end

    def clear_table_comment(table_name)
      execute "COMMENT ON TABLE #{quote_table_name(table_name)} IS NULL"
    end

    def add_index(table_name, column_name, options = {})
      column_name, options = [], column_name if column_name.is_a?(Hash)
      column_names = Array(column_name)
      raise ArgumentError, "No columns and :expression missing from options - cannot create index" if column_names.empty? && options[:expression].blank?
      index_name   = column_names.empty? ? options[:name] : index_name(table_name, :column => column_names)

      if Hash === options # legacy support, since this param was a string
        index_type = options[:unique] ? "UNIQUE" : ""
        index_name = options[:name] || index_name
        conditions = options[:conditions]
      else
        index_type = options
      end

      if column_names.empty? then
        sql = "CREATE #{index_type} INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} USING #{options[:expression]}"
      else
        quoted_column_names = column_names.map { |e| options[:case_sensitive] == false && e.to_s !~ /_id$/ ? "LOWER(#{quote_column_name(e)})" : quote_column_name(e) }

        sql = "CREATE #{index_type} INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} (#{quoted_column_names.join(", ")})"
        sql += " WHERE (#{ ActiveRecord::Base.send(:sanitize_sql, conditions, quote_table_name(table_name)) })" if conditions
      end
      execute sql
    end

    def supports_partial_indexes?
      true
    end
      
    INDEX_CASE_INSENSITIVE_REGEX = /\((.*LOWER\([^:]+(::text)?\).*)\)/i
    INDEX_PARTIAL_REGEX = /\((.*)\)\s+WHERE (.*)$/i
    INDEX_NON_BTREE_REGEX = /((?:gin|gist|hash).*)$/i

    def indexes_with_redhillonrails_core(table_name, name = nil)
      indexes = indexes_without_redhillonrails_core(table_name, name)
      # Process indexes containg expressions and partial indexes
      # Ie. consider 
      result = query(<<-SQL, name)
        SELECT c2.relname, i.indisunique, pg_catalog.pg_get_indexdef(i.indexrelid, 0, true)
          FROM pg_catalog.pg_class c, pg_catalog.pg_class c2, pg_catalog.pg_index i
         WHERE c.relname = '#{table_name}'
           AND c.oid = i.indrelid AND i.indexrelid = c2.oid
           AND i.indisprimary = 'f' 
           AND (i.indexprs IS NOT NULL OR i.indpred IS NOT NULL)
         ORDER BY 1
      SQL


      # Correctly process complex indexes, ie:
      # CREATE INDEX test_index ON custom_pages USING btree (lower(title::text), created_at) WHERE kind = 1 AND author_id = 3
      result.each do |(index_name, unique, index_def)|
        case_sensitive_match = INDEX_CASE_INSENSITIVE_REGEX.match(index_def)
        partial_index_match = INDEX_PARTIAL_REGEX.match(index_def)
        if case_sensitive_match || partial_index_match
          # column_definitions may be ie. 'LOWER(lower)' or 'login, deleted_at' or LOWER(login), deleted_at
          column_definitions = case_sensitive_match ? case_sensitive_match[1] : partial_index_match[1] 

          indexes.delete_if { |index| index.name == index_name } # prevent duplicated indexes
          column_names = determine_index_column_names(column_definitions)

          index = ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, index_name, unique == "t", column_names)
          index.case_sensitive = !case_sensitive_match
          # conditions may be ie. active = true AND deleted_at IS NULL. 
          index.conditions = partial_index_match[2] if partial_index_match 
          indexes << index

        elsif non_btree_match = INDEX_NON_BTREE_REGEX.match(index_def) then
          indexes.delete_if { |index| index.name == index_name } # prevent duplicated indexes

          index = ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, index_name, false, [])
          index.expression = non_btree_match[1]
          indexes << index
        end
      end

      indexes
    end

    def foreign_keys(table_name, name = nil)
      load_foreign_keys(<<-SQL, name)
        SELECT f.conname, pg_get_constraintdef(f.oid), t.relname
          FROM pg_class t, pg_constraint f
         WHERE f.conrelid = t.oid
           AND f.contype = 'f'
           AND t.relname = '#{table_name}'
      SQL
    end

    def reverse_foreign_keys(table_name, name = nil)
      load_foreign_keys(<<-SQL, name)
        SELECT f.conname, pg_get_constraintdef(f.oid), t2.relname
          FROM pg_class t, pg_class t2, pg_constraint f
         WHERE f.confrelid = t.oid
           AND f.conrelid = t2.oid
           AND f.contype = 'f'
           AND t.relname = '#{table_name}'
      SQL
    end

    def views(name = nil)
      schemas = schema_search_path.split(/,/).map { |p| quote(p) }.join(',')
      query(<<-SQL, name).map { |row| row[0] }
        SELECT viewname
          FROM pg_views
         WHERE schemaname IN (#{schemas})
      SQL
    end
    
    def view_definition(view_name, name = nil)
      result = query(<<-SQL, name)
        SELECT pg_get_viewdef(oid)
          FROM pg_class
         WHERE relkind = 'v'
           AND relname = '#{view_name}'
      SQL
      row = result.first
      row.first unless row.nil?
    end

    private

    def load_foreign_keys(sql, name = nil)
      foreign_keys = []

      query(sql, name).each do |row|
          if row[1] =~ /^FOREIGN KEY \((.+?)\) REFERENCES (.+?)\((.+?)\)( ON UPDATE (.+?))?( ON DELETE (.+?))?( (DEFERRABLE|NOT DEFERRABLE))?$/
              name = row[0]
              from_table_name = row[2]
              column_names = $1
              references_table_name = $2
              references_column_names = $3
              on_update = $5
              on_delete = $7
              deferrable = $9 == "DEFERRABLE"
              on_update = on_update.downcase.gsub(' ', '_').to_sym if on_update
              on_delete = on_delete.downcase.gsub(' ', '_').to_sym if on_delete

              foreign_keys << ForeignKeyDefinition.new(name,
                                             from_table_name, column_names.split(', '),
                                             references_table_name.sub(/^"(.*)"$/, '\1'), references_column_names.split(', '),
                                             on_update, on_delete, deferrable)
          end
      end

      foreign_keys
    end

    # Converts form like: column1, LOWER(column2)
    # to: column1, column2
    def determine_index_column_names(column_definitions)
      column_definitions.split(", ").map do |name|
        name = $1 if name =~ /^LOWER\(([^:]+)(::text)?\)$/i
        name = $1 if name =~ /^"(.*)"$/
          name
      end
    end

  end
end
