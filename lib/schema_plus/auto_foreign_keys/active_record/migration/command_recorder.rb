module SchemaAutoForeignKeys
  module ActiveRecord
    module Migration
      module CommandRecorder

        # overrides to add if_exists option
        def invert_add_index(args)
          table, columns, options = *args
          [:remove_index, [table, (options||{}).merge(column: columns, if_exists: true)]]
        end
      end
    end
  end
end
