module RedhillonrailsCore
  module ActiveRecord
    module SchemaDumper
      def self.included(base)
        base.class_eval do
          private
          alias_method_chain :tables, :redhillonrails_core
          alias_method_chain :indexes, :redhillonrails_core
        end
      end

      private

      def tables_with_redhillonrails_core(stream)
        @foreign_keys = StringIO.new
        begin
          tables_without_redhillonrails_core(stream)
          @foreign_keys.rewind
          stream.print @foreign_keys.read
          views(stream)
        ensure
          @foreign_keys = nil
        end
      end

      def indexes_with_redhillonrails_core(table, stream)
        indexes = @connection.indexes(table)
        indexes.each do |index|
          unless index.columns.blank? 
            stream.print "  add_index #{index.table.inspect}, #{index.columns.inspect}, :name => #{index.name.inspect}"
            stream.print ", :unique => true" if index.unique
            stream.print ", :kind => \"#{index.kind}\"" unless index.kind.blank?
            stream.print ", :case_sensitive => false" unless index.case_sensitive?
            stream.print ", :conditions => #{index.conditions.inspect}" unless index.conditions.blank?
          else
            stream.print "  add_index #{index.table.inspect}"
            stream.print ", :name => #{index.name.inspect}"
            stream.print ", :kind => \"#{index.kind}\"" unless index.kind.blank?
            stream.print ", :expression => #{index.expression.inspect}"
          end

          stream.puts
        end
        stream.puts unless indexes.empty?

        foreign_keys(table, @foreign_keys)
      end

      def foreign_keys(table, stream)
        foreign_keys = @connection.foreign_keys(table)
        foreign_keys.each do |foreign_key|
          stream.print "  "
          stream.print foreign_key.to_dump
          stream.puts
        end
        stream.puts unless foreign_keys.empty?
      end

      def views(stream)
        views = @connection.views
        views.each do |view_name|
          definition = @connection.view_definition(view_name)
          stream.print "  create_view #{view_name.inspect}, #{definition.inspect}"
          stream.puts
        end
        stream.puts unless views.empty?
      end
    end
  end
end
