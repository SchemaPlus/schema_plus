require 'middleware'
require 'key_struct'

require_relative "schema_monkey/middleware"
require_relative "schema_monkey/active_record/connection_adapters/abstract_adapter"
require_relative 'schema_monkey/active_record/schema_dumper'
require_relative 'schema_monkey/railtie' if defined?(Rails::Railtie)

module SchemaMonkey

  module ActiveRecord
    module ConnectionAdapters
      autoload :PostgresqlAdapter, 'schema_monkey/active_record/connection_adapters/postgresql_adapter'
    end
  end

  def self.insert
    include_adapters(::ActiveRecord::ConnectionAdapters::AbstractAdapter, :AbstractAdapter)
    include_once(::ActiveRecord::SchemaDumper, SchemaMonkey::ActiveRecord::SchemaDumper)
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
    if submodule = get_const(mod, subname)
      include_once(base, submodule)
    end
  end

  def self.include_once(base, mod)
    base.send(:include, mod) unless base.include? mod
  end

  # ruby 2.* supports mod.const_get("Component::Path") but ruby 1.9.3
  # doesn't
  def self.get_const(mod, name)
    name.to_s.split('::').map(&:to_sym).each do |component|
      return nil unless mod.const_defined?(component)
      mod = mod.const_get(component)
    end
    mod
  end

end
