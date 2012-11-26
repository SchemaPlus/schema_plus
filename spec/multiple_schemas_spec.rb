require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "with multiple schemas" do
  let (:connection) { ActiveRecord::Base.connection }

  before(:all) do
    newdb = case connection.adapter_name
            when /^mysql/i then      "CREATE SCHEMA IF NOT EXISTS schema_plus_test2"
            when /^postgresql/i then "CREATE SCHEMA schema_plus_test2"
            when /^sqlite/i then     "ATTACH ':memory:' AS schema_plus_test2"
            end
    begin
      ActiveRecord::Base.connection.execute newdb
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.message =~ /already exists/
    end

    class User < ::ActiveRecord::Base ; end
  end

  before(:each) do
    define_schema(:auto_create => false) do
      create_table :users, :force => true do |t|
        t.string :login
      end
    end

    connection.execute 'DROP TABLE IF EXISTS schema_plus_test2.users'
    connection.execute 'CREATE TABLE schema_plus_test2.users (login integer)'
  end

  context "with indexes in each schema" do
    before(:each) do
      connection.execute 'CREATE INDEX ' + case connection.adapter_name
      when /^mysql/i then      "index_users_on_login ON schema_plus_test2.users"
      when /^postgresql/i then "index_users_on_login ON schema_plus_test2.users"
      when /^sqlite/i then     "schema_plus_test2.index_users_on_login ON users"
      end + " (login)"
    end

    it "should not find indexes in other schema" do
      User.reset_column_information
      User.indexes.should be_empty
    end

    it "should find index in current schema" do
      connection.execute 'CREATE INDEX index_users_on_login ON users (login)'
      User.reset_column_information
      User.indexes.map(&:name).should == ['index_users_on_login']
    end
  end

  context "with views in each schema" do
    around(:each) do  |example|
      begin
        example.run
      ensure
        connection.execute 'DROP VIEW schema_plus_test2.myview' rescue nil
        connection.execute 'DROP VIEW myview' rescue nil
      end
    end

    before(:each) do
      connection.execute 'CREATE VIEW schema_plus_test2.myview AS SELECT * FROM users'
    end

    it "should not find views in other schema" do
      connection.views.should be_empty
    end

    it "should not find views in this schema" do
      connection.execute 'CREATE VIEW myview AS SELECT * FROM users'
      connection.views.should == ['myview']
    end
  end
end



