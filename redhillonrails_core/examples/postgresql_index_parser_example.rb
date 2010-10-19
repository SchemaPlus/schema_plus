require "example_helper"
require "red_hill_consulting/core/active_record/connection_adapters/postgresql_adapter"

describe RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::PostgresqlAdapter, "simple indexes" do

  before :all do
    @migrator = Class.new(ActiveRecord::Migration) do
      def self.up
        create_table :users do |t|
          t.string :username
        end

        add_index :users, :username
      end

      def self.down
        drop_table :users
      end
    end
  end

  it "should parse the index and return appropriate information" do
    indexes = User.indexes
    indexes.length.should == 1

    index = indexes.first
    index.name.should == "index_users_on_username"
    index.columns.should == ["username"]
    index.unique.should == false
    index.should be_case_sensitive
    index.expression.should be_nil
  end

end

describe RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::PostgresqlAdapter, "unique indexes" do

  before :all do
    @migrator = Class.new(ActiveRecord::Migration) do
      def self.up
        create_table :users do |t|
          t.string :username
        end

        add_index :users, :username, :unique => true, :case_sensitive => true
      end

      def self.down
        drop_table :users
      end
    end
  end

  it "should parse the index and return appropriate information" do
    indexes = User.indexes
    indexes.length.should == 1

    index = indexes.first
    index.name.should == "index_users_on_username"
    index.columns.should == ["username"]
    index.unique.should == true
    index.should be_case_sensitive
    index.expression.should be_nil
  end

end

describe RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::PostgresqlAdapter, "case-insensitive indexes" do

  before :all do
    @migrator = Class.new(ActiveRecord::Migration) do
      def self.up
        create_table :users do |t|
          t.string :username
        end

        add_index :users, :username, :case_sensitive => false
      end

      def self.down
        drop_table :users
      end
    end
  end

  it "should parse the index and return appropriate information" do
    indexes = User.indexes
    indexes.length.should == 1

    index = indexes.first
    index.name.should == "index_users_on_username"
    index.columns.should == ["username"]
    index.unique.should == false
    index.should_not be_case_sensitive
    index.expression.should be_nil
  end

end

describe RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::PostgresqlAdapter, "partial indexes" do

  before :all do
    @migrator = Class.new(ActiveRecord::Migration) do
      def self.up
        create_table :users do |t|
          t.string :username, :state
        end

        add_index :users, :username, :unique => true, :name => "index_users_on_active_usernames", :conditions => {:state => "active"}
      end

      def self.down
        drop_table :users
      end
    end
  end

  it "should parse conditional index and report conditions" do
    indexes = User.indexes
    indexes.length.should == 1

    index = indexes.first
    index.should be_case_sensitive
    index.columns.should == ["username"]

    # FIXME: This is subject to change depending on the PostgreSQL version
    index.conditions.should == "state::text = 'active'::text"
  end

end

describe RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::PostgresqlAdapter, "expression indexes" do

  before :all do
    @migrator = Class.new(ActiveRecord::Migration) do
      def self.up
        create_table :users do |t|
          t.string :username, :state
        end

        add_index :users, :expression => "gin (to_tsvector('english', username))", :name => "index_users_full_text"
      end

      def self.down
        drop_table :users
      end
    end
  end

  it "should parse conditional index and report conditions" do
    indexes = User.indexes
    indexes.length.should == 1

    index = indexes.first
    index.unique.should == false
    index.should be_case_sensitive
    index.columns.should be_nil

    # FIXME: This is subject to change depending on the PostgreSQL version
    index.conditions.should be_nil
    index.expression.should == "gin (to_tsvector('english'::regconfig, username::text))"
  end

end

describe RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::PostgresqlAdapter, "case insensitive + partial index" do

  before :all do
    @migrator = Class.new(ActiveRecord::Migration) do
      def self.up
        create_table :users do |t|
          t.string :username, :state
        end

        add_index :users, :username, :unique => true, :case_sensitive => false, :conditions => {:state => %w(active suspended invited)}
      end

      def self.down
        drop_table :users
      end
    end
  end

  it "should parse as an expression index" do
    indexes = User.indexes
    indexes.length.should == 1

    index = indexes.first
    index.unique.should == false   # We don't attempt to determine if this is true/false when it's an expression index
    index.should be_case_sensitive # Same here: return the default value - expression trumps all other values
    index.columns.should be_nil    # And we know the columns aren't specified when it's an expression

    # FIXME: This is subject to change depending on the PostgreSQL version
    index.conditions.should be_nil
    index.expression.should == "btree (lower(username::text)) WHERE state::text = ANY (ARRAY['active'::character varying, 'suspended'::character varying, 'invited'::character varying]::text[])"
  end

end
