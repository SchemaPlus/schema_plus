require 'spec_helper'

describe "with multiple schemas" do
  def connection
    ActiveRecord::Base.connection
  end

  before(:all) do
    newdb = case connection.adapter_name
            when /^mysql/i then      "CREATE SCHEMA IF NOT EXISTS schema_views_test2"
            when /^postgresql/i then "CREATE SCHEMA schema_views_test2"
            when /^sqlite/i then     "ATTACH ':memory:' AS schema_views_test2"
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

    connection.execute 'DROP TABLE IF EXISTS schema_views_test2.users'
    connection.execute 'CREATE TABLE schema_views_test2.users (id ' + case connection.adapter_name
          when /^mysql/i then      "integer primary key auto_increment"
          when /^postgresql/i then "serial primary key"
          when /^sqlite/i then     "integer primary key autoincrement"
          end + ", login varchar(255))"
  end

  context "with views in each schema" do
    around(:each) do  |example|
      begin
        example.run
      ensure
        connection.execute 'DROP VIEW schema_views_test2.myview' rescue nil
        connection.execute 'DROP VIEW myview' rescue nil
      end
    end

    before(:each) do
      connection.views.each { |view| connection.drop_view view }
      connection.execute 'CREATE VIEW schema_views_test2.myview AS SELECT * FROM users'
    end

    it "should not find views in other schema" do
      expect(connection.views).to be_empty
    end

    it "should find views in this schema" do
      connection.execute 'CREATE VIEW myview AS SELECT * FROM users'
      expect(connection.views).to eq(['myview'])
    end
  end

  context "when using PostGIS", :postgresql => :only do
    before(:all) do
      begin
        connection.execute "CREATE SCHEMA postgis"
      rescue ActiveRecord::StatementInvalid => e
        raise unless e.message =~ /already exists/
      end
    end

    around(:each) do |example|
      begin
        connection.execute "SET search_path to '$user','public','postgis'"
        example.run
      ensure
        connection.execute "SET search_path to '$user','public'"
      end
    end

    before(:each) do
      allow(connection).to receive(:adapter_name).and_return('PostGIS')
    end

    it "should hide views in postgis schema" do
      begin
        connection.create_view "postgis.hidden", "select 1", :force => true
        connection.create_view :myview, "select 2", :force => true
        expect(connection.views).to eq(["myview"])
      ensure
        connection.execute 'DROP VIEW postgis.hidden' rescue nil
        connection.execute 'DROP VIEW myview' rescue nil
      end
    end
  end

end
