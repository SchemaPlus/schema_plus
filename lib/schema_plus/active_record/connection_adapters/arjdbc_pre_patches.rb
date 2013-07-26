require 'arjdbc'
require 'arjdbc/postgresql/adapter'

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

class ActiveRecord::ConnectionAdapters::JdbcColumn
  def initialize_with_nil_config(*args)
    initialize_without_nil_config(nil, *args)
  end
  alias_method_chain :initialize, :nil_config

  def self.extract_value_from_default(default)
    default_value(val)
  end
end
