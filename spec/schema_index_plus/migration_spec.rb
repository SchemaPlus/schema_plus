# encoding: utf-8
require 'spec_helper'

describe ActiveRecord::Migration do

  before(:each) do
    define_schema(:auto_create => true) do

      create_table :users, :force => true do |t|
        t.string :login, :index => { :unique => true }
      end

      create_table :members, :force => true do |t|
        t.string :login
      end

      create_table :comments, :force => true do |t|
        t.string :content
        t.integer :user
        t.integer :user_id
        t.foreign_key :user_id, :users, :id
      end

      create_table :posts, :force => true do |t|
        t.string :content
      end
    end
    class User < ::ActiveRecord::Base ; end
    class Post < ::ActiveRecord::Base ; end
    class Comment < ::ActiveRecord::Base ; end
  end

  context "when table is created" do

    before(:each) do
      @model = Post
    end

    it "should create an index if specified on column" do
      recreate_table(@model) do |t|
        t.integer :state, :index => true
      end
      expect(@model).to have_index.on(:state)
    end

    it "should create a unique index if specified on column" do
      recreate_table(@model) do |t|
        t.integer :state, :index => { :unique => true }
      end
      expect(@model).to have_unique_index.on(:state)
    end

    it "should create a unique index if specified on column using shorthand" do
      recreate_table(@model) do |t|
        t.integer :state, :index => :unique
      end
      expect(@model).to have_unique_index.on(:state)
    end

    it "should pass index length option properly", :mysql => :only do
      recreate_table(@model) do |t|
        t.string :foo
        t.string :bar, :index => { :with => :foo, :length => { :foo => 8, :bar => 12 }}
      end
      index = @model.indexes.first
      expect(Hash[index.columns.zip(index.lengths.map(&:to_i))]).to eq({ "foo" => 8, "bar" => 12})
    end

    it "should create an index if specified explicitly" do
      recreate_table(@model) do |t|
        t.integer :state
        t.index :state
      end
      expect(@model).to have_index.on(:state)
    end

    it "should create a unique index if specified explicitly" do
      recreate_table(@model) do |t|
        t.integer :state
        t.index :state, :unique => true
      end
      expect(@model).to have_unique_index.on(:state)
    end

    it "should create a multiple-column index if specified" do
      recreate_table(@model) do |t|
        t.integer :city
        t.integer :state,       :index => { :with => :city }
      end
      expect(@model).to have_index.on([:state, :city])
    end

    it "should create the index without modifying the input hash" do
      hash = { :with => :foo, :length => { :foo => 8, :bar => 12 }}
      hash_original = hash.dup
      recreate_table(@model) do |t|
        t.string :foo
        t.string :bar, :index => hash
      end
      expect(hash).to eq(hash_original)
    end

  end

  context "when table is changed" do
    before(:each) do
      @model = Post
    end
    [false, true].each do |bulk|
      suffix = bulk ? ' with :bulk option' : ""

      it "should create an index if specified on column"+suffix do
        change_table(@model, :bulk => bulk) do |t|
          t.integer :state, :index => true
        end
        expect(@model).to have_index.on(:state)
      end

    end
  end

  context "when column is added", :sqlite3 => :skip do

    before(:each) do
      @model = Comment
    end

    it "should create an index" do
      add_column(:slug, :string, :index => true) do
        expect(@model).to have_index.on(:slug)
      end
    end

    it "should create an index if specified" do
      add_column(:post_id, :integer, :index => true) do
        expect(@model).to have_index.on(:post_id)
      end
    end

    it "should create a unique index if specified" do
      add_column(:post_id, :integer, :index => { :unique => true }) do
        expect(@model).to have_unique_index.on(:post_id)
      end
    end

    it "should create a unique index if specified by shorthand" do
      add_column(:post_id, :integer, :index => :unique) do
        expect(@model).to have_unique_index.on(:post_id)
      end
    end

    it "should allow custom name for index" do
      index_name = 'comments_post_id_unique_index'
      add_column(:post_id, :integer, :index => { :unique => true, :name => index_name }) do
        expect(@model).to have_unique_index(:name => index_name).on(:post_id)
      end
    end

    protected

    def add_column(column_name, *args)
      table = @model.table_name
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.add_column(table, column_name, *args)
        @model.reset_column_information
        yield if block_given?
        ActiveRecord::Migration.remove_column(table, column_name)
      end
    end

  end


  def recreate_table(model, opts={}, &block)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table model.table_name, opts.merge(:force => true), &block
    end
    model.reset_column_information
  end

  def change_table(model, opts={}, &block)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.change_table model.table_name, opts, &block
    end
    model.reset_column_information
  end

end

