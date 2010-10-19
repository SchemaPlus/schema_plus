require "spec_helper"
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

  before do
    @migrator.up
  end

  after do
    @migrator.down
  end

  it "should parse the index and return appropriate information" do
    indexes = User.indexes
    indexes.length.should == 1

    index = indexes.first
    index.name.should == "index_users_on_username"
    index.unique.should == false
    index.should be_case_sensitive
    index.expression.should be_nil
  end

end
