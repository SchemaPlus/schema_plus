require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "index" do

  let(:migration) { ::ActiveRecord::Migration }
  let(:connection) { ::ActiveRecord::Base.connection }

  describe "add_index" do

    before(:each) do
      connection.tables.each do |table| connection.drop_table table, cascade: true end

      define_schema(:auto_create => false) do
        create_table :users, :force => true do |t|
          t.string :login
          t.datetime :deleted_at
        end

        create_table :posts, :force => true do |t|
          t.text :body
          t.integer :user_id
          t.integer :author_id
        end

        create_table :comments, :force => true do |t|
          t.text :body
          t.integer :post_id
          t.foreign_key :post_id, :posts, :id
        end
      end
      class User < ::ActiveRecord::Base ; end
      class Post < ::ActiveRecord::Base ; end
      class Comment < ::ActiveRecord::Base ; end
    end


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

    unless SchemaPlusHelpers.mysql?
      it "should assign order" do
        add_index(:users, [:login, :deleted_at], :order => {:login => :desc, :deleted_at => :asc})
        index_for([:login, :deleted_at]).orders.should == {"login" => :desc, "deleted_at" => :asc}
      end
    end

    context "for duplicate index" do
      it "should not complain if the index is the same" do
        add_index(:users, :login)
        index_for(:login).should_not be_nil
        ActiveRecord::Base.logger.should_receive(:warn).with(/login.*Skipping/)
        expect { add_index(:users, :login) }.to_not raise_error
        index_for(:login).should_not be_nil
      end
      it "should complain if the index is different" do
        add_index(:users, :login, :unique => true)
        index_for(:login).should_not be_nil
        expect { add_index(:users, :login) }.to raise_error
        index_for(:login).should_not be_nil
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
        @index = User.indexes.detect { |i| i.name == 'users_login_index' }
        @index.expression.should == "upper((login)::text)"
      end

      it "should raise if no column given and expression is missing" do
        expect { add_index(:users, :name => 'users_login_index') }.to raise_error(ArgumentError, /expression/)
      end

      it "should raise if expression without name is given" do
        expect { add_index(:users, :expression => "USING btree (login)") }.to raise_error(ArgumentError, /name/)
      end

      it "should raise if expression is given and case_sensitive is false" do
        expect { add_index(:users, :name => 'users_login_index', :expression => "USING btree (login)", :case_sensitive => false) }.to raise_error(ArgumentError, /use LOWER/i)
      end


    end # of postgresql specific examples

    protected

    def index_for(column_names)
      @index = User.indexes.detect { |i| i.columns == Array(column_names).collect(&:to_s) }
    end

  end

  describe "remove_index" do

    before(:each) do
      connection.tables.each do |table| connection.drop_table table, cascade: true end
      define_schema(:auto_create => false) do
        create_table :users, :force => true do |t|
          t.string :login
          t.datetime :deleted_at
        end
      end
      class User < ::ActiveRecord::Base ; end
    end


    it "removes index by column name (symbols)" do
      add_index :users, :login
      User.indexes.length.should == 1
      remove_index :users, :login
      User.indexes.length.should == 0
    end

    it "removes index by column name (symbols)" do
      add_index :users, :login
      User.indexes.length.should == 1
      remove_index 'users', 'login'
      User.indexes.length.should == 0
    end

    it "removes multi-column index by column names (symbols)" do
      add_index :users, [:login, :deleted_at]
      User.indexes.length.should == 1
      remove_index :users, [:login, :deleted_at]
      User.indexes.length.should == 0
    end

    it "removes multi-column index by column names (strings)" do
      add_index 'users', [:login, :deleted_at]
      User.indexes.length.should == 1
      remove_index 'users', ['login', 'deleted_at']
      User.indexes.length.should == 0
    end

    it "removes index using column option" do
      add_index :users, :login
      User.indexes.length.should == 1
      remove_index :users, column: :login
      User.indexes.length.should == 0
    end

    it "removes index if_exists" do
      add_index :users, :login
      User.indexes.length.should == 1
      remove_index :users, :login, :if_exists => true
      User.indexes.length.should == 0
    end

    it "removes multi-column index if exists" do
      add_index :users, [:login, :deleted_at]
      User.indexes.length.should == 1
      remove_index :users, [:login, :deleted_at], :if_exists => true
      User.indexes.length.should == 0
    end

    it "removes index if_exists using column option" do
      add_index :users, :login
      User.indexes.length.should == 1
      remove_index :users, column: :login, :if_exists => true
      User.indexes.length.should == 0
    end

    it "raises exception if doesn't exist" do
      expect {
        remove_index :users, :login
      }.to raise_error
    end

    it "doesn't raise exception with :if_exists" do
      expect {
        remove_index :users, :login, :if_exists => true
      }.to_not raise_error
    end
  end

  protected
  def add_index(*args)
    migration.suppress_messages do
      migration.add_index(*args)
    end
    User.reset_column_information
  end

  def remove_index(*args)
    migration.suppress_messages do
      migration.remove_index(*args)
    end
    User.reset_column_information
  end

end
