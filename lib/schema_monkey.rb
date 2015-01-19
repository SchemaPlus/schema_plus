require 'hash_keyword_args'
require 'key_struct'
require 'middleware'

require_relative "schema_monkey/middleware"
require_relative "schema_monkey/module_support"
require_relative "schema_monkey/active_record/base"
require_relative "schema_monkey/active_record/connection_adapters/abstract_adapter"
require_relative "schema_monkey/active_record/connection_adapters/table_definition"
require_relative 'schema_monkey/active_record/connection_adapters/schema_statements'
require_relative 'schema_monkey/active_record/migration/command_recorder'
require_relative 'schema_monkey/active_record/schema_dumper'
require_relative 'schema_monkey/railtie' if defined?(Rails::Railtie)

module SchemaMonkey

  extend SchemaMonkey::ModuleSupport

  DBMS = [:Postgresql, :Mysql, :Sqlite3]

  module ActiveRecord
    module ConnectionAdapters
      autoload :PostgresqlAdapter, 'schema_monkey/active_record/connection_adapters/postgresql_adapter'
      autoload :MysqlAdapter, 'schema_monkey/active_record/connection_adapters/mysql_adapter'
      autoload :Sqlite3Adapter, 'schema_monkey/active_record/connection_adapters/sqlite3_adapter'
    end
  end

  def self.insert
    insert_modules
    include_adapters(::ActiveRecord::ConnectionAdapters::AbstractAdapter, :Abstract)
    insert_middleware
  end

  def self.register(mod)
    registered_modules << mod
  end

  def self.registered_modules
    @registered_modules ||= [self]
  end

  def self.include_adapters(base, dbm)
    registered_modules.each do |mod|
      include_if_defined(base, mod, "ActiveRecord::ConnectionAdapters::#{dbm}Adapter")
    end
  end

  def self.insert_modules
    registered_modules.each do |mod|
      get_modules(mod, prefix: 'ActiveRecord', match: /\bActiveRecord\b/, recursive: true).each do |candidate|
        next if candidate.is_a?(Class)
        if (base = get_const(::ActiveRecord, candidate.to_s.sub(/^#{mod}::ActiveRecord::/, '')))
          patch base, mod
        end
      end
      mod.insert if mod.respond_to?(:insert) and mod != self
    end
  end

  def self.insert_middleware(dbm=nil)
    @inserted ||= {}

    if dbm
      match = /\b#{dbm}\b/
      reject = nil
    else
      match = nil
      reject = /\b(#{DBMS.join('|')})\b/
    end

    registered_modules.each do |mod|
      get_modules(mod, prefix: 'Middleware', and_self: true, match: match, reject: reject, recursive: true, respond_to: :insert).each do |middleware|
        next if @inserted[middleware]
        middleware.insert
        @inserted[middleware] = true
      end
    end
  end

end
