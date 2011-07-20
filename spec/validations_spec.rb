require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Validations" do

  before(:all) do
    define_schema
  end

  after(:each) do
    remove_all_models
  end

  context "auto-created" do
    before(:each) do
      with_auto_validations do
        class Article < ActiveRecord::Base ; end

        class Review < ActiveRecord::Base
          belongs_to :article
          belongs_to :news_article, :class_name => 'Article', :foreign_key => :article_id
          schema_plus :validations => { :except => :content }
        end
      end
    end

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
      article2 = Article.new(valid_attributes.merge(:title => 'SchemaPlus 2.0 released'))
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
      review1 = Review.create(:article => article, :author => 'michal')
      review1.should be_valid
      review2 = Review.new(:article => article, :author => 'michal')
      review2.should have_at_least(1).error_on(:article_id)
    end

    it "should validate associations with unmatched column and name" do
      Review.new.should have(1).error_on(:news_article)
    end

    def valid_attributes
      {
        :title => 'SchemaPlus released!',
        :content => "Database matters. Get full use of it but don't write unecessary code. Get SchemaPlus!",
        :state => 3,
        :average_mark => 9.78,
        :active => true
      }
    end

  end

  context "auto-created but changed" do
    before(:each) do
      with_auto_validations do
        class Article < ActiveRecord::Base ; end
        class Review < ActiveRecord::Base
          belongs_to :article
          belongs_to :news_article, :class_name => 'Article', :foreign_key => :article_id
        end
      end
      too_big_content = 'a' * 1000
      @review = Review.new(:content => too_big_content)
    end

    it "would normally have an error" do
      @review.should have(1).error_on(:content)
      @review.should have(1).error_on(:author)
    end

    it "shouldn't validate fields passed to :except option" do
      Review.schema_plus :validations => { :except => :content }
      @review.should have(:no).errors_on(:content)
      @review.should have(1).error_on(:author)
    end

    it "shouldn't validate types passed to :except_type option using full validation" do
      Review.schema_plus :validations => { :except_type => :validates_length_of }
      @review.should have(:no).errors_on(:content)
      @review.should have(1).error_on(:author)
    end

    it "shouldn't validate types passed to :except_type option using shorthand" do
      Review.schema_plus :validations => { :except_type => :length }
      @review.should have(:no).errors_on(:content)
      @review.should have(1).error_on(:author)
    end

    it "should only validate type passed to :only_type option" do
      Review.schema_plus :validations => { :only_type => :length }
      @review.should have(1).error_on(:content)
      @review.should have(:no).errors_on(:author)
    end


    it "shouldn't create validations if locally disabled" do
      Review.schema_plus :validations => { :auto_create => false }
      @review.should have(:no).errors_on(:content)
      @review.should have(:no).error_on(:author)
    end
  end

  context "auto-created disabled" do
    around(:each) do |example|
      with_auto_validations(false, &example)
    end

    before(:each) do
      class Article < ActiveRecord::Base ; end

      class Review < ActiveRecord::Base
        belongs_to :article
        belongs_to :news_article, :class_name => 'Article', :foreign_key => :article_id
      end
      too_big_content = 'a' * 1000
      @review = Review.new(:content => too_big_content)
    end

    it "should not create validation" do
      @review.should have(:no).errors_on(:content)
    end

    it "should create validation if locally enabled" do
      Review.schema_plus :validations => { :auto_create => true }
      @review.should have(1).error_on(:content)
    end

  end

  context "manually invoked" do
    before(:each) do
      class Article < ActiveRecord::Base ; end
      Article.schema_plus :validations => { :only => [:title, :state] }

      class Review < ActiveRecord::Base
        belongs_to :dummy_association
        schema_plus :validations => { :except => :content }
      end
    end

    it "should validate fields passed to :only option" do
      too_big_title = 'a' * 100
      wrong_state = 'unknown'
      article = Article.new(:title => too_big_title, :state => wrong_state)
      article.should have(1).error_on(:title)
      article.should have(1).error_on(:state)
    end

    it "shouldn't validate skipped fields" do
      article = Article.new
      article.should have(:no).errors_on(:content)
      article.should have(:no).errors_on(:average_mark)
    end

    it "shouldn't validate association on unexisting column" do
      Review.new.should have(:no).errors_on(:dummy_association)
    end

    it "shouldn't validate fields passed to :except option" do
      Review.new.should have(:no).errors_on(:content)
    end

    it "should validate all fields but passed to :except option" do
      Review.new.should have(1).error_on(:author)
    end

  end

  context "manually invoked" do
    before(:each) do
      class Review < ActiveRecord::Base
        belongs_to :article
      end
      @columns = Review.content_columns.dup
      Review.schema_plus :validations => { :only => [:title] }
    end

    it "shouldn't validate associations not included in :only option" do
      Review.new.should have(:no).errors_on(:article)
    end

    it "shouldn't change content columns of the model" do
      @columns.should == Review.content_columns
    end

  end

  context "when used with STI" do
    around(:each) { |example| with_auto_validations(&example) }

    it "should set validations on base class" do
      class Review < ActiveRecord::Base ; end
      class PremiumReview < Review ; end
      PremiumReview.new
      Review.new.should have(1).error_on(:author)
    end

    it "shouldn't create doubled validations" do
      class Review < ActiveRecord::Base ; end
      Review.new
      class PremiumReview < Review ; end
      PremiumReview.new.should have(1).error_on(:author)
    end

  end

  protected
  def with_auto_validations(value = true)
    old_value = SchemaPlus.config.validations.auto_create
    begin
      SchemaPlus.config.validations.auto_create = value
      yield
    ensure
      SchemaPlus.config.validations.auto_create = old_value
    end
  end

  def define_schema
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
          t.string :author, :null => false
          t.string :content, :limit => 200
          t.string :type
        end
        add_index :reviews, :article_id, :unique => true

      end
    end
  end

end
