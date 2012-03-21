require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'stringio'

describe "Schema dump" do

  before(:all) do
    SchemaPlus.setup do |config|
      config.foreign_keys.auto_create = false
    end
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        connection.tables.each do |table| drop_table table end

        create_table :users, :force => true do |t|
          t.string :login
          t.datetime :deleted_at
          t.integer :first_post_id
        end

        create_table :posts, :force => true do |t|
          t.text :body
          t.integer :user_id
          t.integer :first_comment_id
          t.string :string_no_default
        end

        create_table :comments, :force => true do |t|
          t.text :body
          t.integer :post_id
          t.integer :commenter_id
        end
      end
    end
    class ::User < ActiveRecord::Base ; end
    class ::Post < ActiveRecord::Base ; end
    class ::Comment < ActiveRecord::Base ; end
  end

  let(:dump_posts) do
    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = %w[users comments]
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end

  let(:dump_all) do
    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = []
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end

  it "should include foreign_key definition" do
    with_foreign_key Post, :user_id, :users, :id do
      dump_posts.should match(to_regexp(%q{t.foreign_key ["user_id"], "users", ["id"]}))
    end
  end

  context "with constraint dependencies" do
    it "should sort in Posts => Comments direction" do
      with_foreign_key Comment, :post_id, :posts, :id do
        dump_all.should match(%r{create_table "posts".*create_table "comments"}m)
      end
    end
    it "should sort in Comments => Posts direction" do
      with_foreign_key Post, :first_comment_id, :comments, :id do
        dump_all.should match(%r{create_table "comments".*create_table "posts"}m)
      end
    end
  end

  context "with date default" do
    if SchemaPlusHelpers.postgresql?
      it "should dump the default hash expr as now()" do
        with_additional_column Post, :posted_at, :datetime, :default => :now do
          dump_posts.should match(to_regexp(%q{t.datetime "posted_at", :default => \{ :expr => "now()" \}}))
        end
      end

      it "should dump the default hash expr as CURRENT_TIMESTAMP" do
        with_additional_column Post, :posted_at, :datetime, :default => {:expr => 'date \'2001-09-28\''} do
          dump_posts.should match(%r{t.datetime "posted_at",\s*:default => '2001-09-28 00:00:00'})
        end
      end
    end

    if SchemaPlusHelpers.sqlite3?
      it "should dump the default hash expr as now" do
        with_additional_column Post, :posted_at, :datetime, :default => :now do
          dump_posts.should match(to_regexp(%q{t.datetime "posted_at", :default => \{ :expr => "(DATETIME('now'))" \}}))
        end
      end

      it "should dump the default hash expr string as now" do
        with_additional_column Post, :posted_at, :datetime, :default => { :expr => "(DATETIME('now'))" } do
          dump_posts.should match(to_regexp(%q{t.datetime "posted_at", :default => \{ :expr => "(DATETIME('now'))" \}}))
        end
      end

      it "should dump the default value normally" do
        with_additional_column Post, :posted_at, :string, :default => "now" do
          dump_posts.should match(%r{t.string  "posted_at",\s*:default => "now"})
        end
      end
    end

  end

  it "should leave out :default when default was changed to null" do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.change_column_default :posts, :string_no_default, nil
    end
    dump_posts.should match(%r{t.string\s+"string_no_default"\s*$})
  end

  it "should include foreign_key options" do
    with_foreign_key Post, :user_id, :users, :id, :on_update => :cascade, :on_delete => :set_null do
      dump_posts.should match(to_regexp(%q{t.foreign_key ["user_id"], "users", ["id"], :on_update => :cascade, :on_delete => :set_null}))
    end
  end

  it "should include index definition" do
    with_index Post, :user_id do
      dump_posts.should match(to_regexp(%q{t.index ["user_id"]}))
    end
  end

  it "should include index name" do
    with_index Post, :user_id, :name => "posts_user_id_index" do
      dump_posts.should match(to_regexp(%q{t.index ["user_id"], :name => "posts_user_id_index"}))
    end
  end
  
  it "should define unique index" do
    with_index Post, :user_id, :name => "posts_user_id_index", :unique => true do
      dump_posts.should match(to_regexp(%q{t.index ["user_id"], :name => "posts_user_id_index", :unique => true}))
    end
  end

  if SchemaPlusHelpers.postgresql?

    it "should define case insensitive index" do
      with_index Post, :name => "posts_user_body_index", :expression => "USING btree (LOWER(body))" do
        dump_posts.should match(to_regexp(%q{t.index ["body"], :name => "posts_user_body_index", :case_sensitive => false}))
      end
    end

    it "should define conditions" do
      with_index Post, :user_id, :name => "posts_user_id_index", :conditions => "user_id IS NOT NULL" do
        dump_posts.should match(to_regexp(%q{t.index ["user_id"], :name => "posts_user_id_index", :conditions => "(user_id IS NOT NULL)"}))
      end
    end

    it "should define expression" do
      with_index Post, :name => "posts_freaky_index", :expression => "USING hash (least(id, user_id))" do
        dump_posts.should match(to_regexp(%q{t.index :name => "posts_freaky_index", :kind => "hash", :expression => "LEAST(id, user_id)"}))
      end
    end

    it "should define kind" do
      with_index Post, :name => "posts_body_index", :expression => "USING hash (body)" do
        dump_posts.should match(to_regexp(%q{t.index ["body"], :name => "posts_body_index", :kind => "hash"}))
      end
    end

  end

  unless SchemaPlusHelpers.sqlite3?
    context "with cyclic foreign key constraints" do
      before (:all) do
        ActiveRecord::Base.connection.add_foreign_key(Comment.table_name, :commenter_id, User.table_name, :id)
        ActiveRecord::Base.connection.add_foreign_key(Comment.table_name, :post_id, Post.table_name, :id)
        ActiveRecord::Base.connection.add_foreign_key(Post.table_name, :first_comment_id, Comment.table_name, :id)
        ActiveRecord::Base.connection.add_foreign_key(Post.table_name, :user_id, User.table_name, :id)
        ActiveRecord::Base.connection.add_foreign_key(User.table_name, :first_post_id, Post.table_name, :id)
      end

      it "should not raise an error" do
        expect { dump_all }.should_not raise_error
      end

      it "should dump constraints after the tables they reference" do
        dump_all.should match(%r{create_table "comments".*foreign_key.*\["first_comment_id"\], "comments", \["id"\]}m)
        dump_all.should match(%r{create_table "posts".*foreign_key.*\["first_post_id"\], "posts", \["id"\]}m)
        dump_all.should match(%r{create_table "posts".*foreign_key.*\["post_id"\], "posts", \["id"\]}m)
        dump_all.should match(%r{create_table "users".*foreign_key.*\["commenter_id"\], "users", \["id"\]}m)
        dump_all.should match(%r{create_table "users".*foreign_key.*\["user_id"\], "users", \["id"\]}m)
      end
    end
  end

  protected
  def to_regexp(string)
    Regexp.new(Regexp.escape(string))
  end

  def with_additional_column(model, column_name, column_type, options)
    table_columns = model.columns.reject{|column| column.name == 'id'}
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table model.table_name, :force => true do |t|
        table_columns.each do |column|
          t.column column.name, column.type, :default => column.default
        end
        t.column column_name, column_type, options
      end
    end
    yield
  end

  def with_foreign_key(model, columns, referenced_table_name, referenced_columns, options = {})
    table_columns = model.columns.reject{|column| column.name == 'id'}
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table model.table_name, :force => true do |t|
        table_columns.each do |column|
          t.column column.name, column.type
        end
        t.foreign_key columns, referenced_table_name, referenced_columns, options
      end
    end
    model.reset_column_information
    begin
      yield
    ensure
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.create_table model.table_name, :force => true do |t|
          table_columns.each do |column|
            t.column column.name, column.type
          end
        end
      end
    end
  end

  def with_index(model, columns, options = {})
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.add_index(model.table_name, columns, options)
    end
    model.reset_column_information
    begin
      yield
    ensure
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.remove_index(model.table_name, :name => determine_index_name(model, columns, options))
      end
    end
  end

  def determine_index_name(model, columns, options)
    name = columns[:name] if columns.is_a?(Hash)
    name ||= options[:name]
    name ||= model.indexes.detect { |index| index.table == model.table_name.to_s && index.columns == Array(columns).collect(&:to_s) }.name
    name
  end

  def determine_foreign_key_name(model, columns, options)
    name = options[:name] 
    name ||= model.foreign_keys.detect { |fk| fk.table_name == model.table_name.to_s && fk.column_names == Array(columns).collect(&:to_s) }.name
  end

end
