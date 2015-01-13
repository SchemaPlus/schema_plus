module SchemaPlus
  module ActiveRecord
    module Migration
      module CommandRecorder
        include SchemaPlus::ActiveRecord::ColumnOptionsHandler

        attr_accessor :schema_plus_config #:nodoc:

        def self.included(base) #:nodoc:
          base.class_eval do
            alias_method_chain :add_column, :schema_plus
            alias_method_chain :add_reference, :schema_plus
            alias_method_chain :invert_add_index, :schema_plus
            alias_method_chain :invert_add_foreign_key, :schema_plus
          end
        end

        def add_column_with_schema_plus(table_name, name, type, options = {}) #:nodoc:
          schema_plus_normalize_column_options(options)
          add_column_without_schema_plus(table_name, name, type, options)
          revertable_schema_plus_handle_column_options(table_name, name, options, :config => schema_plus_config)
          self
        end

        # seems like this is fixing a rails bug:
        #   change_table foo, :bulk => true { |t| t.references :bar } 
        # results in an 'unknown method :add_reference_sql' (with mysql2)
        #
        # should track it down separately and submit a patch/fix to rails
        #
        def add_reference_with_schema_plus(table_name, ref_name, options = {}) #:nodoc:
          polymorphic = options.delete(:polymorphic)
          options[:references] = nil if polymorphic
          # ugh.  copying and pasting code from ::ActiveRecord::ConnectionAdapters::SchemaStatements#add_reference
          index_options = options.delete(:index)
          add_column(table_name, "#{ref_name}_id", :integer, options)
          add_column(table_name, "#{ref_name}_type", :string, polymorphic.is_a?(Hash) ? polymorphic : options) if polymorphic
          add_index(table_name, polymorphic ? %w[id type].map{ |t| "#{ref_name}_#{t}" } : "#{ref_name}_id", index_options.is_a?(Hash) ? index_options : {}) if index_options

          self
        end

        def revertable_schema_plus_handle_column_options(table_name, name, options, config)
          length = commands.length
          schema_plus_handle_column_options(table_name, name, options, config)
          if reverting
            rev = []
            while commands.length > length
              cmd = commands.pop
              rev.unshift cmd unless cmd[0].to_s =~ /^add_/
            end
            commands.concat rev
          end
        end

        def invert_add_foreign_key_with_schema_plus(args)
          table_name, column_names, references_table_name, references_column_names, options = args
          [:remove_foreign_key, [table_name, column_names, references_table_name, references_column_names, (options||{}).merge(if_exists: true)]]
        end

        def invert_add_index_with_schema_plus(args)
          table, columns, options = *args
          [:remove_index, [table, (options||{}).merge(column: columns, if_exists: true)]]
        end

        def invert_remove_foreign_key(args)
          [:add_foreign_key, args]
        end

      end
    end
  end
end
