module SchemaIndexPlus
  module ActiveRecord
    module ConnectionAdapters
      module MysqlAdapter

        def remove_index_sql(table_name, options)
          # strange.  this is only called by command_recorder, but i
          # haven't been able to construct a spec which calls where it
          # doesn't end up skipping.  i suspect the recorded
          # remove_index_sql may be inserted in an attempt to invert an
          # auto_create'd index; but for mysql those don't get created.
          # WBN to track this down better.
          skip = options.delete(:if_exists) and not index_exists?(table_name, options[:column], options)
          return skip ? [] : super
        end
      end
    end
  end
end
