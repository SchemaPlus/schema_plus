module SchemaPlusTables
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter
        # pg gem defines a drop_table with fewer options than our Abstract
        # one, so use the abstract one instead
        def drop_table(name, options={})
          SchemaPlusTables::ActiveRecord::ConnectionAdapters::AbstractAdapter.instance_method(:drop_table).bind(self).call(name, options)
        end
      end
    end
  end
end
