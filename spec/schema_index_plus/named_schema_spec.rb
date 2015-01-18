require 'spec_helper'

describe "with multiple schemas" do
  def connection
    ActiveRecord::Base.connection
  end

  before(:all) do
    newdb = case connection.adapter_name
            when /^mysql/i then      "CREATE SCHEMA IF NOT EXISTS schema_index_plus_test2"
            when /^postgresql/i then "CREATE SCHEMA schema_index_plus_test2"
            when /^sqlite/i then     "ATTACH ':memory:' AS schema_index_plus_test2"
            end
    begin
      ActiveRecord::Base.connection.execute newdb
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.message =~ /already exists/
    end

    class User < ::ActiveRecord::Base ; end
  end

  before(:each) do
    define_schema do
      create_table :users, :force => true do |t|
        t.string :login
      end
    end

    connection.execute 'DROP TABLE IF EXISTS schema_index_plus_test2.users'
    connection.execute 'CREATE TABLE schema_index_plus_test2.users (id ' + case connection.adapter_name
          when /^mysql/i then      "integer primary key auto_increment"
          when /^postgresql/i then "serial primary key"
          when /^sqlite/i then     "integer primary key autoincrement"
          end + ", login varchar(255))"
  end

  context "with indexes in each schema" do
    before(:each) do
      connection.execute 'CREATE INDEX ' + case connection.adapter_name
      when /^mysql/i then      "index_users_on_login ON schema_index_plus_test2.users"
      when /^postgresql/i then "index_users_on_login ON schema_index_plus_test2.users"
      when /^sqlite/i then     "schema_index_plus_test2.index_users_on_login ON users"
      end + " (login)"
    end

    it "should not find indexes in other schema" do
      User.reset_column_information
      expect(User.indexes).to be_empty
    end

    it "should find index in current schema" do
      connection.execute 'CREATE INDEX index_users_on_login ON users (login)'
      User.reset_column_information
      expect(User.indexes.map(&:name)).to eq(['index_users_on_login'])
    end
  end

end

