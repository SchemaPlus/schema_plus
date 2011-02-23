# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ActiveRecord::Base do
  include ActiveSchemaHelpers

  around(:each) do |example|
    with_fk_auto_create(&example)
  end

  context "in basic case" do
    before(:all) do
      create_tables(
        "posts", {}, {},
        "comments", {}, { :post_id => {} }
      )
      @post = Class.new(ActiveRecord::Base) do set_table_name "posts" end
      @comment = Class.new(ActiveRecord::Base) do set_table_name "comments" end
    end
    it "should create belongs_to association" do
      reflection = @comment.reflect_on_association(:post)
      reflection.should_not be_nil
      reflection.macro.should == :belongs_to
      reflection.options[:class_name].should == "Post"
      reflection.options[:foreign_key].should == "post_id"
    end
    it "should create has_many association" do
      reflection = @post.reflect_on_association(:comments)
      reflection.should_not be_nil
      reflection.macro.should == :has_many
      reflection.options[:class_name].should == "Comment"
      reflection.options[:foreign_key].should == "post_id"
    end
  end

  it "should override auto_create negatively" do
    with_associations_auto_create(true) do
      create_tables(
        "posts", {}, {},
        "comments", {}, { :post_id => {} }
      )
      @post = Class.new(ActiveRecord::Base) do
        set_table_name "posts"
        active_schema :associations => { :auto_create => false }
      end
      @comment = Class.new(ActiveRecord::Base) do set_table_name "comments" end
      @post.reflect_on_association(:comments).should be_nil
      @comment.reflect_on_association(:post).should_not be_nil
    end
  end

  it "should override auto_create positively" do
    with_associations_auto_create(false) do
      create_tables(
        "posts", {}, {},
        "comments", {}, { :post_id => {} }
      )
      @post = Class.new(ActiveRecord::Base) do
        set_table_name "posts"
        active_schema :associations => { :auto_create => true }
      end
      @comment = Class.new(ActiveRecord::Base) do set_table_name "comments" end
      @post.reflect_on_association(:comments).should_not be_nil
      @comment.reflect_on_association(:post).should be_nil
    end
  end


  context "with unique index" do
    before(:all) do
      create_tables(
        "posts", {}, {},
        "comments", {}, { :post_id => {:index => { :unique => true} } }
      )
      @post = Class.new(ActiveRecord::Base) do set_table_name "posts" end
      @comment = Class.new(ActiveRecord::Base) do set_table_name "comments" end
    end
    it "should create has_one association" do
      reflection = @post.reflect_on_association(:comment)
      reflection.should_not be_nil
      reflection.macro.should == :has_one
      reflection.options[:class_name].should == "Comment"
      reflection.options[:foreign_key].should == "post_id"
    end
  end

  context "with prefixed column names" do
    before(:all) do
      create_tables(
        "posts", {}, {},
        "comments", {}, { :subject_post_id => { :references => :posts} }
      )
      @post = Class.new(ActiveRecord::Base) do set_table_name "posts" end
      @comment = Class.new(ActiveRecord::Base) do set_table_name "comments" end
    end
    it "should name belongs_to according to column" do
      reflection = @comment.reflect_on_association(:subject_post)
      reflection.should_not be_nil
      reflection.macro.should == :belongs_to
      reflection.options[:class_name].should == "Post"
      reflection.options[:foreign_key].should == "subject_post_id"
    end

    it "should name has_many using 'as column'" do
      reflection = @post.reflect_on_association(:comments_as_subject)
      reflection.should_not be_nil
      reflection.macro.should == :has_many
      reflection.options[:class_name].should == "Comment"
      reflection.options[:foreign_key].should == "subject_post_id"
    end
  end

  context "with arbitrary column names" do
    before(:all) do
      create_tables(
        "posts", {}, {},
        "comments", {}, { :subject => {:references => :posts} }
      )
      @post = Class.new(ActiveRecord::Base) do set_table_name "posts" end
      @comment = Class.new(ActiveRecord::Base) do set_table_name "comments" end
    end
    it "should name belongs_to according to column" do
      reflection = @comment.reflect_on_association(:subject)
      reflection.should_not be_nil
      reflection.macro.should == :belongs_to
      reflection.options[:class_name].should == "Post"
      reflection.options[:foreign_key].should == "subject"
    end

    it "should name has_many using 'as column'" do
      reflection = @post.reflect_on_association(:comments_as_subject)
      reflection.should_not be_nil
      reflection.macro.should == :has_many
      reflection.options[:class_name].should == "Comment"
      reflection.options[:foreign_key].should == "subject"
    end
  end


  context "with position" do
    before(:all) do
      create_tables(
        "posts", {}, {},
        "comments", {}, { :post_id => {}, :position => {} }
      )
      @post = Class.new(ActiveRecord::Base) do set_table_name "posts" end
      @comment = Class.new(ActiveRecord::Base) do set_table_name "comments" end
    end
    it "should create ordered has_many association" do
      reflection = @post.reflect_on_association(:comments)
      reflection.should_not be_nil
      reflection.macro.should == :has_many
      reflection.options[:class_name].should == "Comment"
      reflection.options[:foreign_key].should == "post_id"
      reflection.options[:order].to_s.should == "position"
    end
  end

  context "with shared prefix" do
    before(:all) do
      create_tables(
        "posts", {}, {},
        "post_comments", {}, { :post_id => {} }
      )
      @post = Class.new(ActiveRecord::Base) do set_table_name "posts" end
      @comment = Class.new(ActiveRecord::Base) do set_table_name "post_comments" end
    end
    it "should use concise association name" do
      reflection = @post.reflect_on_association(:comments)
      reflection.should_not be_nil
      reflection.macro.should == :has_many
      reflection.options[:class_name].should == "PostComment"
      reflection.options[:foreign_key].should == "post_id"
    end
  end

  context "with joins table" do
    before(:all) do
      create_tables(
        "posts", {}, {},
        "tags", {}, {},
        "posts_tags", {:id => false}, { :post_id => {}, :tag_id => {}}
      )
      @post = Class.new(ActiveRecord::Base) do set_table_name "posts" end
      @tag = Class.new(ActiveRecord::Base) do set_table_name "tags" end
    end
    it "should create has_and_belongs_to_many association" do
      reflection = @post.reflect_on_association(:tags)
      reflection.should_not be_nil
      reflection.macro.should == :has_and_belongs_to_many
      reflection.options[:class_name].should == "Tag"
      reflection.options[:join_table].should == "posts_tags"
    end
  end

  protected

  def with_fk_auto_create(value = true, &block)
    save = ActiveSchema.config.foreign_keys.auto_create
    begin
      ActiveSchema.config.foreign_keys.auto_create = value
      yield
    ensure
      ActiveSchema.config.foreign_keys.auto_create = save
    end
  end

  def with_associations_auto_create(value, &block)
    save = ActiveSchema.config.associations.auto_create
    begin
      ActiveSchema.config.associations.auto_create = value
      yield
    ensure
      ActiveSchema.config.associations.auto_create = save
    end
  end

  def create_tables(*table_defs)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Base.connection.tables.each do |table|
        ActiveRecord::Migration.drop_table table
      end
      table_defs.each_slice(3) do |table_name, opts, columns_with_options|
        ActiveRecord::Migration.create_table table_name, opts do |t|
          columns_with_options.each_pair do |column, options|
            t.integer column, options
          end
        end
      end
    end
  end

end
