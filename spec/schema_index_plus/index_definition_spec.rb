require 'spec_helper'


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
      expect(@index).not_to be_nil
    end

  end

  it "should not crash on equality test with nil" do
    index = ActiveRecord::ConnectionAdapters::IndexDefinition.new(:table, :column)
    expect{index == nil}.to_not raise_error
    expect(index == nil).to be false
  end


  context "when index is ordered", :mysql => :skip do

    quotes = [
      ["unquoted", ''],
      ["double-quoted", '"'],
    ]
    quotes += [
      ["single-quoted", "'"],
      ["back-quoted", '`']
    ] if SchemaDev::Rspec::Helpers.sqlite3?

    quotes.each do |quotename, quote|
      it "index definition includes orders for #{quotename} columns" do
        migration.execute "CREATE INDEX users_login_index ON users (#{quote}login#{quote} DESC, #{quote}deleted_at#{quote} ASC)"
        User.reset_column_information
        index = index_definition(%w[login deleted_at])
        expect(index.orders).to eq({"login" => :desc, "deleted_at" => :asc})
      end

    end
  end


  context "when case insensitive is added", :postgresql => :only do

    before(:each) do
      migration.execute "CREATE INDEX users_login_index ON users(LOWER(login))"
      User.reset_column_information
      @index = User.indexes.detect { |i| i.expression =~ /lower\(\(login\)::text\)/i }
    end

    it "is included in User.indexes" do
      expect(@index).not_to be_nil
    end

    it "is not case_sensitive" do
      expect(@index).not_to be_case_sensitive
    end

    it "defines expression" do
      expect(@index.expression).to eq("lower((login)::text)")
    end

    it "doesn't define where" do
      expect(@index.where).to be_nil
    end

  end


  context "when index is partial" do
    before(:each) do
      migration.execute "CREATE INDEX users_login_index ON users(login) WHERE deleted_at IS NULL"
      User.reset_column_information
      @index = index_definition("login")
    end

    it "is included in User.indexes" do
      expect(User.indexes.select { |index| index.columns == ["login"] }.size).to eq(1)
    end

    it "is case_sensitive" do
      expect(@index).to be_case_sensitive
    end

    it "doesn't define expression" do
      expect(@index.expression).to be_nil
    end

    it "defines where" do
      expect(@index.where).to match %r{[(]?deleted_at IS NULL[)]?}
    end

  end if ::ActiveRecord::Migration.supports_partial_index?

  context "when index contains expression", :postgresql => :only do
    before(:each) do
      migration.execute "CREATE INDEX users_login_index ON users (extract(EPOCH from deleted_at)) WHERE deleted_at IS NULL"
      User.reset_column_information
      @index = User.indexes.detect { |i| i.expression.present? }
    end

    it "exists" do
      expect(@index).not_to be_nil
    end

    it "doesnt have columns defined" do
      expect(@index.columns).to be_empty
    end

    it "is case_sensitive" do
      expect(@index).to be_case_sensitive
    end

    it "defines expression" do
      expect(@index.expression).to eq("date_part('epoch'::text, deleted_at)")
    end

    it "defines where" do
      expect(@index.where).to eq("(deleted_at IS NULL)")
    end

  end

  context "when index has a non-btree type", :postgresql => :only do
    before(:each) do
      migration.execute "CREATE INDEX users_login_index ON users USING hash(login)"
      User.reset_column_information
      @index = User.indexes.detect { |i| i.name == "users_login_index" }
    end

    it "exists" do
      expect(@index).not_to be_nil
    end

    it "defines using" do
      expect(@index.using).to eq(:hash)
    end

    it "does not define expression" do
      expect(@index.expression).to be_nil
    end

    it "does not define order" do
      expect(@index.orders).to be_blank
    end
  end



  protected
  def index_definition(column_names)
    User.indexes.detect { |index| index.columns == Array(column_names) }
  end


end
