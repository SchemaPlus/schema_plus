require 'arjdbc'

class ActiveRecord::ConnectionAdapters::JdbcColumn
  def initialize_with_nil_config(*args)
    initialize_without_nil_config(nil, *args)
  end
  alias_method_chain :initialize, :nil_config

  def self.extract_value_from_default(default)
    default_value(val)
  end
end
