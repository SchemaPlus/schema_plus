require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/user'

describe "add_index" do

  let(:migration) { ActiveRecord::Migration }

  after(:each) do
    migration.suppress_messages do
      migration.remove_index(:users, :name => @index.name) if @index
    end
  end

  it "should create index when called without additional options" do
    add_index(:users, :login)
    index_for(:login).should_not be_nil
  end

  it "should create unique index" do
    add_index(:users, :login, :unique => true)
    index_for(:login).unique.should == true
  end

  it "should assign given name" do
    add_index(:users, :login, :name => 'users_login_index')
    index_for(:login).name.should == 'users_login_index'
  end

  if ActiveRecord::Base.connection.class.include?(RedHillConsulting::Core::ActiveRecord::ConnectionAdapters::PostgresqlAdapter)

    it "should assign conditions" do
      add_index(:users, :login, :conditions => 'deleted_at IS NULL')
      index_for(:login).conditions.should == 'deleted_at IS NULL'
    end

    it "should assign expression" do
      add_index(:users, :expression => "USING hash (login) WHERE deleted_at IS NULL", :name => 'users_login_index')
      @index = User.indexes.detect { |i| i.expression.present? }
      @index.expression.should == "USING hash (login) WHERE deleted_at IS NULL"
    end

    it "should raise if no column given and expression is missing" do
      expect { add_index(:users, :name => 'users_login_index') }.should raise_error(ArgumentError)
    end

    it "should raise if expression without name is given" do
      expect { add_index(:users, :expression => "USING btree (login)") }.should raise_error(ArgumentError)
    end

  end # of postgresql specific examples

  protected
  def add_index(*args)
    migration.suppress_messages do
      migration.add_index(*args)
    end
    User.reset_column_information
  end

  def index_for(column_names)
    @index = User.indexes.detect { |i| i.columns == Array(column_names).collect(&:to_s) }
  end


end
