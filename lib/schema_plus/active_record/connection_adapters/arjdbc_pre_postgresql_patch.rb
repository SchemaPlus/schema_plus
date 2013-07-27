require 'arjdbc'
require 'arjdbc/postgresql/adapter'
require 'schema_plus/active_record/connection_adapters/arjdbc_pre_patch'

module ::ArJdbc
  module PostgreSQL
    def schema_search_path
      @config[:schema_search_path] || select_rows('SHOW search_path')[0][0]
    end

    def query(*args)
      select(*args).map(&:values)
    end
  end
end

class ActiveRecord::ConnectionAdapters::PostgreSQLColumn
  def initialize(name, *args)
    super
  end
end

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  def indexes(*args)
    super
  end
  def exec_cache(*args)
    super
  end
end
