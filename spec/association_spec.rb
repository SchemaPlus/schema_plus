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
    it "shouldn't raise an exception when model is instantiated" do
      expect { @post.new }.should_not raise_error
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

  context "regarding concise names" do

    def prefix_one
      create_tables(
        "posts", {}, {},
        "post_comments", {}, { :post_id => {} }
      )
      @post = Class.new(ActiveRecord::Base) do set_table_name "posts" end
      @comment = Class.new(ActiveRecord::Base) do set_table_name "post_comments" end
    end

    def suffix_one
      create_tables(
        "posts", {}, {},
        "comment_posts", {}, { :post_id => {} }
      )
      @post = Class.new(ActiveRecord::Base) do set_table_name "posts" end
      @comment = Class.new(ActiveRecord::Base) do set_table_name "comment_posts" end
    end

    def prefix_both
      create_tables(
        "blog_page_posts", {}, {},
        "blog_page_comments", {}, { :blog_page_post_id => {} }
      )
      @post = Class.new(ActiveRecord::Base) do set_table_name "blog_page_posts" end
      @comment = Class.new(ActiveRecord::Base) do set_table_name "blog_page_comments" end
    end

    it "should use concise association name for one prefix" do
      with_associations_config(:auto_create => true, :concise_names => true) do
        prefix_one
        reflection = @post.reflect_on_association(:comments)
        reflection.should_not be_nil
        reflection.macro.should == :has_many
        reflection.options[:class_name].should == "PostComment"
        reflection.options[:foreign_key].should == "post_id"
      end
    end

    it "should use concise association name for one suffix" do
      with_associations_config(:auto_create => true, :concise_names => true) do
        suffix_one
        reflection = @post.reflect_on_association(:comments)
        reflection.should_not be_nil
        reflection.macro.should == :has_many
        reflection.options[:class_name].should == "CommentPost"
        reflection.options[:foreign_key].should == "post_id"
      end
    end

    it "should use concise association name for shared prefixes" do
      with_associations_config(:auto_create => true, :concise_names => true) do
        prefix_both
        reflection = @post.reflect_on_association(:comments)
        reflection.should_not be_nil
        reflection.macro.should == :has_many
        reflection.options[:class_name].should == "BlogPageComment"
        reflection.options[:foreign_key].should == "blog_page_post_id"
      end
    end

    it "should use full names and not concise names when so configured" do
      with_associations_config(:auto_create => true, :concise_names => false) do
        prefix_one
        reflection = @post.reflect_on_association(:post_comments)
        reflection.should_not be_nil
        reflection.macro.should == :has_many
        reflection.options[:class_name].should == "PostComment"
        reflection.options[:foreign_key].should == "post_id"
        reflection = @post.reflect_on_association(:comments)
        reflection.should be_nil
      end
    end

    it "should use concise names and not full names when so configured" do
      with_associations_config(:auto_create => true, :concise_names => true, :full_names_always => false) do
        prefix_one
        reflection = @post.reflect_on_association(:comments)
        reflection.should_not be_nil
        reflection.macro.should == :has_many
        reflection.options[:class_name].should == "PostComment"
        reflection.options[:foreign_key].should == "post_id"
        reflection = @post.reflect_on_association(:post_comments)
        reflection.should be_nil
      end
    end

    it "should use both concise names and full names when so configured" do
      with_associations_config(:auto_create => true, :concise_names => true, :full_names_always => true) do
        prefix_one
        reflection = @post.reflect_on_association(:comments)
        reflection.should_not be_nil
        reflection.macro.should == :has_many
        reflection.options[:class_name].should == "PostComment"
        reflection.options[:foreign_key].should == "post_id"
        reflection = @post.reflect_on_association(:post_comments)
        reflection.should_not be_nil
        reflection.macro.should == :has_many
        reflection.options[:class_name].should == "PostComment"
        reflection.options[:foreign_key].should == "post_id"
        reflection = @post.reflect_on_association(:post_comments)
      end
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

  context "regarding existing methods" do
    before(:all) do
      create_tables(
        "types", {}, {},
        "posts", {}, {:type_id => {}}
      )
    end
    it "should define association normally if no existing method is defined" do
      @type_without = Class.new(ActiveRecord::Base) do set_table_name "types" end
      @type_without.reflect_on_association(:posts).should_not be_nil # sanity check for this context
    end
    it "should not define association over existing public method" do
      @type_with = Class.new(ActiveRecord::Base) do
        set_table_name "types"
        def posts
          :existing
        end
      end
      @type_with.reflect_on_association(:posts).should be_nil
    end
    it "should not define association over existing private method" do
      @type_with = Class.new(ActiveRecord::Base) do
        set_table_name "types"
        private
        def posts
          :existing
        end
      end
      @type_with.reflect_on_association(:posts).should be_nil
    end
    it "should define association :type over (deprecated) kernel method" do
      @post_without = Class.new(ActiveRecord::Base) do set_table_name "posts" end
      @post_without.reflect_on_association(:type).should_not be_nil
    end
    it "should not define association :type over model method" do
      @post_with = Class.new(ActiveRecord::Base) do
        set_table_name "posts"
        def type
          :existing
        end
      end
      @post_with.reflect_on_association(:type).should be_nil
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
    with_associations_config(:auto_create => value, &block)
  end

  def with_associations_config(opts, &block)
    save = Hash[opts.keys.collect{|key| [key, ActiveSchema.config.associations.send(key)]}]
    begin
      ActiveSchema.config.associations.update_attributes(opts)
      yield
    ensure
      ActiveSchema.config.associations.update_attributes(save)
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
