require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/post'
require 'models/comment'

describe "SchemaValidations" do

  let(:schema) { ActiveRecord::Schema }

  before(:all) do
    define_schema
  end

  context "is enabled" do

    before(:each) do
      Post.schema_validations
      Comment.schema_validations
    end

    # TODO: use rspec-rails
    it "should be valid with valid attributes" do
      Post.new(valid_attributes).should be_valid
    end

    it "should validate content presence" do
      post = Post.new
      post.valid?
      post.errors[:content].should have(1).error
    end

    it "should check title length" do
      post = Post.new(:title => 'a' * 100)
      post.valid?
      post.errors[:title].should have(1).error
    end

    it "should validate state numericality" do
      post = Post.new(:state => 'unknown')
      post.valid?
      post.errors[:state].should have(1).error
    end

    it "should validate if state is integer" do
      post = Post.new(:state => 1.23)
      post.valid?
      post.errors[:state].should have(1).error
    end

    it "should validate average_mark numericality" do
      post = Post.new(:average_mark => "high")
      post.should have(1).error_on(:average_mark)
    end

    it "should validate boolean fields" do
      post = Post.new(:active => nil)
      post.should have(1).error_on(:active)
    end

    it "should validate title uniqueness" do
      post1 = Post.create(valid_attributes)
      post2 = Post.new(:title => valid_attributes[:title])
      post2.should have(1).error_on(:title)
      post1.destroy
    end

    it "should validate state uniqueness in scope of 'active' value" do
      post1 = Post.create(valid_attributes)
      post2 = Post.new(valid_attributes.merge(:title => 'ActiveSchema 2.0 released'))
      post2.should_not be_valid
      post2.toggle(:active)
      post2.should be_valid
      post1.destroy
    end

    it "should validate presence of belongs_to association" do
      comment = Comment.new
      comment.should have(1).error_on(:post)
    end

    it "should validate uniqueness of belongs_to association" do
      post = Post.create(valid_attributes)
      post.should be_valid
      comment1 = Comment.create(:post => post)
      comment1.should be_valid
      comment2 = Comment.new(:post => post)
      comment2.should have(1).error_on(:post_id)
    end

  end
  def valid_attributes
    {
      :title => 'ActiveSchema released!',
      :content => "Database matters. Get full use of it but don't write unecessary code. Get ActiveSchema!",
      :state => 3,
      :average_mark => 9.78,
      :active => true
    }
  end

  def define_schema
    ActiveRecord::Migration.suppress_messages do
      schema.define do
        connection.tables.each do |table| drop_table table end

        create_table :posts, :force => true do |t|
          t.string :title, :limit => 50
          t.text  :content, :null => false
          t.integer :state
          t.float   :average_mark, :null => false
          t.boolean :active, :null => false
        end
        add_index :posts, :title, :unique => true
        add_index :posts, [:state, :active], :unique => true

        create_table :comments, :force => true do |t|
          t.integer :post_id, :null => false
        end
        add_index :comments, :post_id, :unique => true
      end
    end
    Post.reset_column_information
    Comment.reset_column_information
  end

end
