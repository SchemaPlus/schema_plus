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
    connection.execute 'CREATE TABLE schema_plus_test2.users (id ' + case connection.adapter_name
          when /^mysql/i then      "integer primary key auto_increment"
          when /^postgresql/i then "serial primary key"
          when /^sqlite/i then     "integer primary key autoincrement"
          end + ", login varchar(255))"
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
      connection.views.each { |view| connection.drop_view view }
      connection.execute 'CREATE VIEW schema_plus_test2.myview AS SELECT * FROM users'
    end

    it "should not find views in other schema" do
      connection.views.should be_empty
    end

    it "should find views in this schema" do
      connection.execute 'CREATE VIEW myview AS SELECT * FROM users'
      connection.views.should == ['myview']
    end
  end

  context "with foreign key in each schema" do
    before(:each) do
      class Comment < ::ActiveRecord::Base ; end
      connection.execute 'DROP TABLE IF EXISTS schema_plus_test2.comments'
      connection.execute 'CREATE TABLE schema_plus_test2.comments (user_id integer,' + case connection.adapter_name
            when /^mysql/i then      "foreign key (user_id) references schema_plus_test2.users (id))"
            when /^postgresql/i then "foreign key (user_id) references schema_plus_test2.users (id))"
            when /^sqlite/i then     "foreign key (user_id) references users (id))"
            end
    end

    around(:each) do |example|
      begin
        example.run
      ensure
        connection.execute 'DROP TABLE IF EXISTS comments'
        connection.execute 'DROP TABLE IF EXISTS schema_plus_test2.comments'
      end
    end

    it "should not find foreign keys in other schema" do
      connection.create_table :comments, :force => true do |t|
        t.integer :user_id, :foreign_key => false
      end
      Comment.reset_column_information
      Comment.foreign_keys.length.should == 0
      User.reset_column_information
      User.reverse_foreign_keys.length.should == 0
    end

    it "should find foreign keys in this schema" do
      connection.create_table :comments, :force => true do |t|
        t.integer :user_id, :foreign_key => true
      end
      Comment.reset_column_information
      Comment.foreign_keys.map(&:column_names).flatten.should == ["user_id"]
      User.reset_column_information
      User.reverse_foreign_keys.map(&:column_names).flatten.should == ["user_id"]
    end

  end

  context "foreign key migrations" do
    before(:each) do
      define_schema do
        create_table "schema_plus_test2.groups", :force => true do |t|
        end
        create_table "schema_plus_test2.members", :force => true do |t|
          t.integer :group_id, :foreign_key => true
        end
      end
      class Group < ::ActiveRecord::Base
        self.table_name = "schema_plus_test2.groups"
      end
      class Member < ::ActiveRecord::Base
        self.table_name = "schema_plus_test2.members"
      end
    end

    around(:each) do |example|
      begin
        example.run
      ensure
        connection.execute 'DROP TABLE IF EXISTS schema_plus_test2.members'
        connection.execute 'DROP TABLE IF EXISTS schema_plus_test2.groups'
      end
    end

    it "should find foreign keys" do
      Member.foreign_keys.should_not be_empty
    end

    it "should find reverse foreign keys" do
      Group.reverse_foreign_keys.should_not be_empty
    end

    it "should reference table in same schema" do
      Member.foreign_keys.first.references_table_name.should == "schema_plus_test2.groups"
    end

    it "should include the schema in the constraint name" do
      Member.foreign_keys.first.name.should == "fk_schema_plus_test2_members_group_id"
    end
  end

end



