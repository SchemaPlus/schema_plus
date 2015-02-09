module SchemaPlusForeignKeys
  module Mixins
    module VisitTableDefinition
      def self.included(base) #:nodoc:
        base.alias_method_chain :visit_TableDefinition, :schema_plus_foreign_keys
      end

      def visit_TableDefinition_with_schema_plus_foreign_keys(o) #:nodoc:
        create_sql = visit_TableDefinition_without_schema_plus_foreign_keys(o)
        last_chunk = ") #{o.options}"

        unless create_sql.end_with?(last_chunk)
          raise "Internal Error: Can't find '#{last_chunk}' at end of '#{create_sql}' - Rails internals have changed!"
        end

        unless o.foreign_keys.empty?
          create_sql[create_sql.size - last_chunk.size, 0] = ', ' + o.foreign_keys.map(&:to_sql) * ', '
        end
        create_sql
      end
    end
  end
end
