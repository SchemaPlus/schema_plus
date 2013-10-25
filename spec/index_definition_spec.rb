require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe "Index definition" do

  let(:migration) { ::ActiveRecord::Migration }
  
  before(:all) do
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

  around(:each) do |example|
    migration.suppress_messages do
      example.run
    end
  end

  after(:each) do
    migration.remove_index :users, :name => 'users_login_index' if migration.index_name_exists? :users, 'users_login_index', true
  end

  context "when index is multicolumn" do
    before(:each) do
      migration.execute "CREATE INDEX users_login_index ON users (login, deleted_at)"
      User.reset_column_information
      @index = index_definition(%w[login deleted_at])
    end

    it "is included in User.indexes" do
      @index.should_not be_nil
    end

  end

  it "should correctly report supports_partial_indexes?" do
    query = lambda { migration.execute "CREATE INDEX users_login_index ON users(login) WHERE deleted_at IS NULL" }
    if migration.supports_partial_indexes?
      query.should_not raise_error
    else
      query.should raise_error
    end
  end

  it "should not crash on equality test with nil" do
    index = ActiveRecord::ConnectionAdapters::IndexDefinition.new(:table, :column)
    expect{index == nil}.to_not raise_error
    (index == nil).should be_false
  end


  unless SchemaPlusHelpers.mysql?
    context "when index is ordered" do

      quotes = [
        ["unquoted", ''],
        ["double-quoted", '"'],
      ]
      quotes += [
        ["single-quoted", "'"],
        ["back-quoted", '`']
      ] if SchemaPlusHelpers.sqlite3?

      quotes.each do |quotename, quote|
        it "index definition includes orders for #{quotename} columns" do
          migration.execute "CREATE INDEX users_login_index ON users (#{quote}login#{quote} DESC, #{quote}deleted_at#{quote} ASC)"
          User.reset_column_information
          index = index_definition(%w[login deleted_at])
          index.orders.should == {"login" => :desc, "deleted_at" => :asc}
        end

      end
    end
  end


  if SchemaPlusHelpers.postgresql?

    context "when case insensitive is added" do

      before(:each) do
        migration.execute "CREATE INDEX users_login_index ON users(LOWER(login))"
        User.reset_column_information
        @index = User.indexes.detect { |i| i.expression =~ /lower\(\(login\)::text\)/i }
      end

      it "is included in User.indexes" do
        @index.should_not be_nil
      end

      it "is not case_sensitive" do
        @index.should_not be_case_sensitive
      end

      it "its column should not be case sensitive" do
        User.columns.find{|column| column.name == "login"}.should_not be_case_sensitive
      end

      it "defines expression" do
        @index.expression.should == "lower((login)::text)"
      end

      it "doesn't define conditions" do
        @index.conditions.should be_nil
      end

    end


    context "when index is partial and column is not downcased" do
      before(:each) do
        migration.execute "CREATE INDEX users_login_index ON users(login) WHERE deleted_at IS NULL"
        User.reset_column_information
        @index = index_definition("login")
      end

      it "is included in User.indexes" do
        User.indexes.select { |index| index.columns == ["login"] }.should have(1).item
      end

      it "is case_sensitive" do
        @index.should be_case_sensitive
      end

      it "doesn't define expression" do
        @index.expression.should be_nil
      end

      it "defines conditions" do
        @index.conditions.should == "(deleted_at IS NULL)"
      end

    end

    context "when index contains expression" do
      before(:each) do
        migration.execute "CREATE INDEX users_login_index ON users (extract(EPOCH from deleted_at)) WHERE deleted_at IS NULL"
        User.reset_column_information
        @index = User.indexes.detect { |i| i.expression.present? }
      end

      it "exists" do
        @index.should_not be_nil
      end

      it "doesnt have columns defined" do
        @index.columns.should be_empty
      end

      it "is case_sensitive" do
        @index.should be_case_sensitive
      end

      it "defines expression" do
        @index.expression.should == "date_part('epoch'::text, deleted_at)"
      end

      it "defines conditions" do
        @index.conditions.should == "(deleted_at IS NULL)"
      end

    end

    context "when index has a non-btree type" do
      before(:each) do
        migration.execute "CREATE INDEX users_login_index ON users USING hash(login)"
        User.reset_column_information
        @index = User.indexes.detect { |i| i.name == "users_login_index" }
      end

      it "exists" do
        @index.should_not be_nil
      end

      it "defines kind" do
        @index.kind.should == "hash"
      end

      it "does not define expression" do
        @index.expression.should be_nil
      end

      it "does not define order" do
        @index.orders.should be_blank
      end
    end


  end # of postgresql specific examples

  protected
  def index_definition(column_names)
    User.indexes.detect { |index| index.columns == Array(column_names) }
  end


end
