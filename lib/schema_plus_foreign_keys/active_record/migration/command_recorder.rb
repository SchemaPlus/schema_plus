module SchemaPlusForeignKeys
  module ActiveRecord
    module Migration
      module CommandRecorder

        attr_accessor :schema_plus_config #:nodoc:

        # seems like this is fixing a rails bug:
        #   change_table foo, :bulk => true { |t| t.references :bar }
        # results in an 'unknown method :add_reference_sql' (with mysql2)
        #
        # should track it down separately and submit a patch/fix to rails
        #
        def add_reference(table_name, ref_name, options = {}) #:nodoc:
          polymorphic = options.delete(:polymorphic)
          options[:references] = nil if polymorphic
          # ugh.  copying and pasting code from ::ActiveRecord::ConnectionAdapters::SchemaStatements#add_reference
          index_options = options.delete(:index)
          add_column(table_name, "#{ref_name}_id", :integer, options)
          add_column(table_name, "#{ref_name}_type", :string, polymorphic.is_a?(Hash) ? polymorphic : options) if polymorphic
          add_index(table_name, polymorphic ? %w[id type].map{ |t| "#{ref_name}_#{t}" } : "#{ref_name}_id", index_options.is_a?(Hash) ? index_options : {}) if index_options

          self
        end

        # overrides to add if_exists option
        def invert_add_index(args)
          table, columns, options = *args
          [:remove_index, [table, (options||{}).merge(column: columns, if_exists: true)]]
        end

      end
    end
  end
end
