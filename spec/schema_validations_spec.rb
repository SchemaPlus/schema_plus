require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define do
    connection.tables.each do |table| drop_table table end

    create_table :articles, :force => true do |t|
      t.string :title, :limit => 50
      t.text  :content, :null => false
      t.integer :state
      t.float   :average_mark, :null => false
      t.boolean :active, :null => false
    end
    add_index :articles, :title, :unique => true
    add_index :articles, [:state, :active], :unique => true

    create_table :reviews, :force => true do |t|
      t.integer :article_id, :null => false
      t.string :content, :limit => 200
    end
    add_index :reviews, :article_id, :unique => true

    create_table :pingbacks, :force => true do |t|
      t.integer :article_id, :null => false
      t.string :url, :limit => 2048, :null => false
      t.float :popularity, :null => false
    end

    create_table :likes, :force => true do |t|
      t.string :username, :limit => 50, :null => false
      t.string :source, :limit => 100, :null => false
    end

  end
end

ActiveSchema.config.validations.auto_create = true

class Article < ActiveRecord::Base
end
class Review < ActiveRecord::Base
  belongs_to :article
  belongs_to :news_article, :class_name => 'Article', :foreign_key => :article_id
  schema_validations :except => :content
end

ActiveSchema.config.validations.auto_create = false

class Pingback < ActiveRecord::Base
  belongs_to :article
  belongs_to :news_article, :class_name => 'Article', :foreign_key => :article_id
  schema_validations :only => [:url, :article]
end

class Like < ActiveRecord::Base
  belongs_to :dummy_association
  schema_validations :except => :source
end

describe "SchemaValidations" do

  context "auto-created" do

    it "should be valid with valid attributes" do
      Article.new(valid_attributes).should be_valid
    end

    it "should validate content presence" do
      post = Article.new.should have(1).error_on(:content)
    end

    it "should check title length" do
      Article.new(:title => 'a' * 100).should have(1).error_on(:title)
    end

    it "should validate state numericality" do
      Article.new(:state => 'unknown').should have(1).error_on(:state)
    end

    it "should validate if state is integer" do
      Article.new(:state => 1.23).should have(1).error_on(:state)
    end

    it "should validate average_mark numericality" do
      Article.new(:average_mark => "high").should have(1).error_on(:average_mark)
    end

    it "should validate boolean fields" do
      Article.new(:active => nil).should have(1).error_on(:active)
    end

    it "should validate title uniqueness" do
      article1 = Article.create(valid_attributes)
      article2 = Article.new(:title => valid_attributes[:title])
      article2.should have(1).error_on(:title)
      article1.destroy
    end

    it "should validate state uniqueness in scope of 'active' value" do
      article1 = Article.create(valid_attributes)
      article2 = Article.new(valid_attributes.merge(:title => 'ActiveSchema 2.0 released'))
      article2.should_not be_valid
      article2.toggle(:active)
      article2.should be_valid
      article1.destroy
    end

    it "should validate presence of belongs_to association" do
      review = Review.new
      review.should have(1).error_on(:article)
    end

    it "should validate uniqueness of belongs_to association" do
      article = Article.create(valid_attributes)
      article.should be_valid
      review1 = Review.create(:article => article)
      review1.should be_valid
      review2 = Review.new(:article => article)
      review2.should have_at_least(1).error_on(:article_id)
    end

    it "shouldn't validate association on unexisting column" do
      Pingback.new.should have(:no).errors_on(:dummy_association)
    end

    it "should validate associations with unmatched column and name" do
      Review.new.should have(1).error_on(:news_article)
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

  end

  context "auto-created but changed" do

    it "shouldn't validate fields passed to :except option" do
      too_big_content = 'a' * 1000
      Review.new(:content => too_big_content).should have(:no).errors_on(:content)
    end

  end

  context "manually invoked" do

    it "should validate fields passed to :only option" do
      pingback = Pingback.new
      pingback.should have(1).error_on(:url)
      pingback.should have(1).error_on(:article)
    end

    it "shouldn't validate skipped fields" do
      pingback = Pingback.new
      pingback.should have(:no).errors_on(:popularity)
    end

    it "shouldn't validate fields passed to :except option" do
      like = Like.new
      like.should have(:no).errors_on(:source)
    end

    it "should validate all fields but passed to :except option" do
      like = Like.new
      like.should have(1).error_on(:username)
    end

    it "shouldn't validate associations not included in :only option" do
      Pingback.new.should have(:no).errors_on(:news_article)
    end

  end

end
