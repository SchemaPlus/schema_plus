# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ActiveRecord::Migration do
  include SchemaPlusHelpers

  before(:all) do
    create_schema do

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
    with_fk_auto_create(true) do
      class User < ::ActiveRecord::Base ; end
      class Post < ::ActiveRecord::Base ; end
      class Comment < ::ActiveRecord::Base ; end
    end
  end

  around(:each) do |example|
    with_fk_config(:auto_create => true, :auto_index => true) { example.run }
  end

  context "when table is created" do

    before(:each) do
      @model = Post
    end

    it "should create foreign keys" do
      create_table(:user_id => {},
                   :author_id => { :references => :users },
                   :member_id => { :references => nil } )
      @model.should reference(:users, :id).on(:user_id)
      @model.should reference(:users, :id).on(:author_id)
      @model.should_not reference.on(:member_id)
    end

  end

  unless SchemaPlusHelpers.sqlite3?

    context "when column is added" do

      before(:each) do
        @model = Comment
      end

      it "should create a foreign key" do
        add_column(:post_id, :integer) do
          @model.should reference(:posts, :id).on(:post_id)
        end
      end

      it "should create an index" do
        add_column(:post_id, :integer) do
          @model.should have_index.on(:post_id)
        end
      end

    end

    context "when column is changed" do

      before(:each) do
        @model = Comment
      end

      it "should create a foreign key" do
        change_column :user, :string, :references => [:users, :login]
        @model.should reference(:users, :login).on(:user)
        change_column :user, :string, :references => nil
      end

      it "should remove a foreign key" do
        @model.should reference(:users, :id).on(:user_id)
        change_column :user_id, :integer, :references => nil
        @model.should_not reference(:users, :id).on(:user_id)
      end

    end

    context "when column is removed" do

      before(:each) do
        @model = Comment
      end

      it "should remove a foreign key" do
        suppress_messages do
          target.add_column(@model.table_name, :post_id, :integer)
          target.remove_column(@model.table_name, :post_id)
        end
        @model.should_not reference(:posts)
      end

      it "should remove an index" do
        suppress_messages do
          target.add_column(@model.table_name, :post_id, :integer)
          target.remove_column(@model.table_name, :post_id)
        end
        @model.should_not have_index.on(:post_id)
      end

    end

  end

  protected
  def target
    ActiveRecord::Migration.connection
  end

  def add_column(column_name, *args)
    table = @model.table_name
    suppress_messages do
      target.add_column(table, column_name, *args)
      @model.reset_column_information
      yield if block_given?
      target.remove_column(table, column_name)
    end
  end

  def change_column(column_name, *args)
    table = @model.table_name
    suppress_messages do
      target.change_column(table, column_name, *args)
      @model.reset_column_information
    end
  end

  def create_table(columns_with_options)
    suppress_messages do
      target.create_table @model.table_name, :force => true do |t|
        columns_with_options.each_pair do |column, options|
          t.send :integer, column, options
        end
      end
      @model.reset_column_information
    end
  end

  def with_fk_config(opts, &block)
    save = Hash[opts.keys.collect{|key| [key, SchemaPlus.config.foreign_keys.send(key)]}]
    begin
      SchemaPlus.config.foreign_keys.update_attributes(opts)
      yield
    ensure
      SchemaPlus.config.foreign_keys.update_attributes(save)
    end
  end

end
