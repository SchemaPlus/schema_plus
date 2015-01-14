require 'middleware'
require_relative "schema_monkey/active_record/connection_adapters/abstract_adapter"
require_relative "schema_monkey/middleware"
require_relative 'schema_monkey/railtie' if defined?(Rails::Railtie)

module SchemaMonkey

  module ActiveRecord
    module ConnectionAdapters
      autoload :PostgresqlAdapter, 'schema_plus/schema_monkey/active_record/connection_adapters/postgresql_adapter'
    end
  end

  def self.insert
    include_adapters(::ActiveRecord::ConnectionAdapters::AbstractAdapter, :AbstractAdapter)
    insert_modules
  end

  def self.register(mod)
    modules << mod
  end

  def self.modules
    @modules ||= [self]
  end

  def self.include_adapters(base, name)
    modules.each do |mod|
      include_if_defined(base, mod, "ActiveRecord::ConnectionAdapters::#{name}")
    end
  end

  def self.insert_modules
    modules.each do |mod|
      mod.insert if mod.respond_to?(:insert) and mod != self
    end
  end

  def self.include_if_defined(base, mod, subname)
    if mod.const_defined?(subname)
      submodule = mod.const_get(subname)
      base.send(:include, submodule) unless base.include?(submodule)
    end
  end
end
