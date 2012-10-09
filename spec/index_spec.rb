require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/user'

describe "add_index" do

  before(:all) do
    load_core_schema
  end

  let(:migration) { ::ActiveRecord::Migration }

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

  context "for duplicate index" do
    it "should not complain if the index is the same" do
      add_index(:users, :login)
      index_for(:login).should_not be_nil
      ActiveRecord::Base.logger.should_receive(:warn).with(/login.*Skipping/)
      expect { add_index(:users, :login) }.to_not raise_error
      index_for(:login).should_not be_nil
    end
    if ActiveRecord::VERSION::STRING >= "3.0"
      it "should complain if the index is different" do
        add_index(:users, :login, :unique => true)
        index_for(:login).should_not be_nil
        expect { add_index(:users, :login) }.to raise_error
        index_for(:login).should_not be_nil
      end
    end
  end

  if SchemaPlusHelpers.postgresql?

    it "should assign conditions" do
      add_index(:users, :login, :conditions => 'deleted_at IS NULL')
      index_for(:login).conditions.should == '(deleted_at IS NULL)'
    end

    it "should assign expression, conditions and kind" do
      add_index(:users, :expression => "USING hash (upper(login)) WHERE deleted_at IS NULL", :name => 'users_login_index')
      @index = User.indexes.detect { |i| i.expression.present? }
      @index.expression.should == "upper((login)::text)"
      @index.conditions.should == "(deleted_at IS NULL)"
      @index.kind.should       == "hash"
    end

    it "should allow to specify expression, conditions and kind separately" do
      add_index(:users, :kind => "hash", :expression => "upper(login)", :conditions => "deleted_at IS NULL", :name => 'users_login_index')
      @index = User.indexes.detect { |i| i.expression.present? }
      @index.expression.should == "upper((login)::text)"
      @index.conditions.should == "(deleted_at IS NULL)"
      @index.kind.should       == "hash"
    end

    it "should allow to specify kind" do
      add_index(:users, :login, :kind => "hash")
      index_for(:login).kind.should == 'hash'
    end

    it "should allow to specify actual expression only" do
      add_index(:users, :expression => "upper(login)", :name => 'users_login_index')
      @index = User.indexes.detect { |i| i.expression.present? }
      @index.expression.should == "upper((login)::text)"
    end

    it "should raise if no column given and expression is missing" do
      expect { add_index(:users, :name => 'users_login_index') }.to raise_error(ArgumentError)
    end

    it "should raise if expression without name is given" do
      expect { add_index(:users, :expression => "USING btree (login)") }.to raise_error(ArgumentError)
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
