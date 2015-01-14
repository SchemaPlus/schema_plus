require 'middleware'
require_relative "schema_monkey/active_record/connection_adapters/abstract_adapter"
require_relative "schema_monkey/middleware"

module SchemaMonkey

  module ActiveRecord
    module ConnectionAdapters
      autoload :PostgresqlAdapter, 'schema_plus/schema_monkey/active_record/connection_adapters/postgresql_adapter'
    end
  end

  def self.insert
    return if @inserted
    @inserted = true
    modules.each do |mod|
      mod.insert if mod.respond_to?(:insert)
    end
    ::ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, SchemaMonkey::ActiveRecord::ConnectionAdapters::AbstractAdapter)
  end

  def self.register(mod)
    modules << mod
    adapters << mod.const_get(:ConnectionAdapters) if mod.const_defined?(:ConnectionAdapters)
  end

  def self.modules
    @modules ||= []
  end

  def self.adapters
    @adapters ||= [SchemaMonkey::ActiveRecord::ConnectionAdapters]
  end

end
