require 'spec_helper'

describe "with multiple schemas" do
  def connection
    ActiveRecord::Base.connection
  end

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
      expect(Comment.foreign_keys.length).to eq(0)
      User.reset_column_information
      expect(User.reverse_foreign_keys.length).to eq(0)
    end

    it "should find foreign keys in this schema" do
      connection.create_table :comments, :force => true do |t|
        t.integer :user_id, :foreign_key => true
      end
      Comment.reset_column_information
      expect(Comment.foreign_keys.map(&:column).flatten).to eq(["user_id"])
      User.reset_column_information
      expect(User.reverse_foreign_keys.map(&:column).flatten).to eq(["user_id"])
    end

  end

  context "foreign key migrations" do
    before(:each) do
      define_schema do
        create_table "items", :force => true do |t|
        end
        create_table "schema_plus_test2.groups", :force => true do |t|
        end
        create_table "schema_plus_test2.members", :force => true do |t|
          t.integer :item_id, :foreign_key => true unless SchemaDev::Rspec::Helpers.mysql?
          t.integer :group_id, :foreign_key => { references: "schema_plus_test2.groups" }
        end
      end
      class Group < ::ActiveRecord::Base
        self.table_name = "schema_plus_test2.groups"
      end
      class Item < ::ActiveRecord::Base
        self.table_name = "items"
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
        connection.execute 'DROP TABLE IF EXISTS items'
      end
    end

    it "should find foreign keys" do
      expect(Member.foreign_keys).not_to be_empty
    end

    it "should find reverse foreign keys" do
      expect(Group.reverse_foreign_keys).not_to be_empty
    end

    it "should reference table in same schema" do
      expect(Member.foreign_keys.map(&:to_table)).to include "schema_plus_test2.groups"
    end

    it "should reference table in default schema", :mysql => :skip do
      expect(Member.foreign_keys.map(&:to_table)).to include "items"
    end

    it "should include the schema in the constraint name" do
      expected_names = ["fk_schema_plus_test2_members_group_id"]
      expected_names << "fk_schema_plus_test2_members_item_id" unless SchemaDev::Rspec::Helpers.mysql?
      expect(Member.foreign_keys.map(&:name).sort).to match_array(expected_names.sort)
    end
  end

end
