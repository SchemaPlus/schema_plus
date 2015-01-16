require 'middleware'
require 'key_struct'

require_relative "schema_monkey/middleware"
require_relative "schema_monkey/active_record/connection_adapters/abstract_adapter"
require_relative "schema_monkey/active_record/connection_adapters/table_definition"
require_relative 'schema_monkey/active_record/connection_adapters/schema_statements'
require_relative 'schema_monkey/active_record/schema_dumper'
require_relative 'schema_monkey/railtie' if defined?(Rails::Railtie)

module SchemaMonkey

  module ActiveRecord
    module ConnectionAdapters
      autoload :PostgresqlAdapter, 'schema_monkey/active_record/connection_adapters/postgresql_adapter'
      autoload :MysqlAdapter, 'schema_monkey/active_record/connection_adapters/mysql_adapter'
      autoload :Sqlite3Adapter, 'schema_monkey/active_record/connection_adapters/sqlite3_adapter'
    end
  end

  def self.insert
    include_adapters(::ActiveRecord::ConnectionAdapters::AbstractAdapter, :AbstractAdapter)
    patch ::ActiveRecord::SchemaDumper
    patch ::ActiveRecord::ConnectionAdapters::TableDefinition
    patch ::ActiveRecord::ConnectionAdapters::AbstractAdapter::SchemaCreation
    insert_modules
    insert_middleware
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

  def self.insert_middleware(submodules=nil)
    modname = ['Middleware', *Array.wrap(submodules)].join('::')
    modules.each do |mod|
      if middleware = get_const(mod, modname) and middleware.respond_to? :insert
        middleware.insert
      end
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

  def self.patch(base, mod = SchemaMonkey)
    patch = get_const(mod, base)
    raise "#{mod} does not contain a definition of #{base}" unless patch
    include_once(base, patch)
  end

  # ruby 2.* supports mod.const_get("Component::Path") but ruby 1.9.3
  # doesn't.  And neither has a version that can return nil rather than
  # raising a NameError
  def self.get_const(mod, name)
    name.to_s.split('::').map(&:to_sym).each do |component|
      begin
        mod = mod.const_get(component, false)
      rescue NameError
        return nil
      end
    end
    mod
  end

end
