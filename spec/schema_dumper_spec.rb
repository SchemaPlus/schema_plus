require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'stringio'

describe "Schema dump" do

  before(:all) do
    SchemaPlus.setup do |config|
      config.foreign_keys.auto_create = false
    end
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        connection.tables.each do |table| drop_table table, :cascade => true end

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
          t.integer :short_id
          t.string :str_short
          t.integer :integer_col
          t.float :float_col
          t.decimal :decimal_col
          t.datetime :datetime_col
          t.timestamp :timestamp_col
          t.time :time_col
          t.date :date_col
          t.binary :binary_col
          t.boolean :boolean_col
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

  it "should include foreign_key definition" do
    with_foreign_key Post, :user_id, :users, :id do
      dump_posts.should match(to_regexp(%q{t.foreign_key ["user_id"], "users", ["id"]}))
    end
  end

  it "should include foreign_key name" do
    with_foreign_key Post, :user_id, :users, :id, :name => "yippee" do
      dump_posts.should match /foreign_key.*user_id.*users.*id.*:name => "yippee"/
    end
  end

  it "should sort foreign_key definitions" do
    with_foreign_keys Comment, [ [ :post_id, :posts, :id ], [ :commenter_id, :users, :id ]] do
      dump_schema.should match(/foreign_key.+commenter_id.+foreign_key.+post_id/m)
    end
  end

  context "with constraint dependencies" do
    it "should sort in Posts => Comments direction" do
      with_foreign_key Comment, :post_id, :posts, :id do
        dump_schema.should match(%r{create_table "posts".*create_table "comments"}m)
      end
    end
    it "should sort in Comments => Posts direction" do
      with_foreign_key Post, :first_comment_id, :comments, :id do
        dump_schema.should match(%r{create_table "comments".*create_table "posts"}m)
      end
    end

    it "should handle regexp in ignore_tables" do
      with_foreign_key Comment, :post_id, :posts, :id do
        dump = dump_schema(:ignore => /post/)
        dump.should match /create_table "comments"/
        dump.should_not match /create_table "posts"/
      end
    end

  end

  context "with date default" do
    if SchemaPlusHelpers.postgresql?
      it "should dump the default hash expr as now()" do
        with_additional_column Post, :posted_at, :datetime, :default => :now do
          dump_posts.should match(%r{t\.datetime\s+"posted_at",\s*(?:default:|:default =>)\s*\{\s*(?:expr:|:expr\s*=>)\s*"now\(\)"\s*\}})
        end
      end

      it "should dump the default hash expr as CURRENT_TIMESTAMP" do
        with_additional_column Post, :posted_at, :datetime, :default => {:expr => 'date \'2001-09-28\''} do
          dump_posts.should match(%r{t\.datetime\s+"posted_at",\s*(?:default:|:default =>)\s*'2001-09-28 00:00:00'})
        end
      end

      it "can dump a complex default expression" do
        with_additional_column Post, :name, :string, :default => {:expr => 'substring(random()::text from 3 for 6)'} do
          dump_posts.should match(%r{t\.string\s+"name",\s*(?:default:|:default\s*=>)\s*{\s*(?:expr:|:expr\s*=>)\s*"\\"substring\\"\(\(random\(\)\)::text, 3, 6\)"\s*}})
        end
      end
    end

    if SchemaPlusHelpers.sqlite3?
      it "should dump the default hash expr as now" do
        with_additional_column Post, :posted_at, :datetime, :default => :now do
          dump_posts.should match(%r{t\.datetime\s+"posted_at",\s*(?:default:|:default =>)\s*\{\s*(?:expr:|:expr =>)\s*"\(DATETIME\('now'\)\)"\s*\}})
        end
      end

      it "should dump the default hash expr string as now" do
        with_additional_column Post, :posted_at, :datetime, :default => { :expr => "(DATETIME('now'))" } do
          dump_posts.should match(%r{t\.datetime\s+"posted_at",\s*(?:default:|:default =>)\s*\{\s*(?:expr:|:expr =>)\s*"\(DATETIME\('now'\)\)"\s*\}})
        end
      end

      it "should dump the default value normally" do
        with_additional_column Post, :posted_at, :string, :default => "now" do
          dump_posts.should match(%r{t\.string\s*"posted_at",\s*(?:default:|:default =>)\s*"now"})
        end
      end
    end

  end

  it "should leave out :default when default was changed to null" do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.change_column_default :posts, :string_no_default, nil
    end
    dump_posts.should match(%r{t\.string\s+"string_no_default"\s*$})
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
    with_index Post, :user_id, :name => "custom_name" do
      dump_posts.should match(to_regexp(%q{t.index ["user_id"], :name => "custom_name"}))
    end
  end
  
  it "should define unique index" do
    with_index Post, :user_id, :name => "posts_user_id_index", :unique => true do
      dump_posts.should match(to_regexp(%q{t.index ["user_id"], :name => "posts_user_id_index", :unique => true}))
    end
  end

  it "should sort indexes" do
    with_index Post, :user_id do
      with_index Post, :short_id do
        dump_posts.should match(/on_short_id.+on_user_id/m)
      end
    end
  end

  unless SchemaPlusHelpers.mysql?

    it "should include index order" do
      with_index Post, [:user_id, :first_comment_id, :short_id], :order => { :user_id => :asc, :first_comment_id => :desc } do
        dump_posts.should match(%r{t.index \["user_id", "first_comment_id", "short_id"\],.*:order => {"user_id" => :asc, "first_comment_id" => :desc, "short_id" => :asc}})
      end
    end

  end

  if SchemaPlusHelpers.postgresql?

    it "should define case insensitive index" do
      with_index Post, [:body, :string_no_default], :case_sensitive => false do
        dump_posts.should match(to_regexp(%q{t.index ["body", "string_no_default"], :name => "index_posts_on_body_and_string_no_default", :case_sensitive => false}))
      end
    end

    it "should define index with type cast" do
      with_index Post, [:integer_col], :name => "index_with_type_cast", :expression => "LOWER(integer_col::text)" do
        dump_posts.should match(to_regexp(%q{t.index :name => "index_with_type_cast", :expression => "lower((integer_col)::text)"}))
      end
    end


    it "should define case insensitive index with mixed ids and strings" do
      with_index Post, [:user_id, :str_short, :short_id, :body], :case_sensitive => false do
        dump_posts.should match(to_regexp(%q{t.index ["user_id", "str_short", "short_id", "body"], :name => "index_posts_on_user_id_and_str_short_and_short_id_and_body", :case_sensitive => false}))
      end
    end

    [:integer, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean].each do |col_type|
      col_name = "#{col_type}_col"
      it "should define case insensitive index that includes an #{col_type}" do
        with_index Post, [:user_id, :str_short, col_name, :body], :case_sensitive => false do
          dump_posts.should match(to_regexp(%Q!t.index ["user_id", "str_short", "#{col_name}", "body"], :name => "index_posts_on_user_id_and_str_short_and_#{col_name}_and_body", :case_sensitive => false!))
        end
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

    it "should dump unique: true with expression (Issue #142)" do
      with_index Post, :name => "posts_user_body_index", :unique => true, :expression => "BTRIM(LOWER(body))" do
        dump_posts.should match(%r{#{to_regexp(%q{t.index :name => "posts_user_body_index", :unique => true, :expression => "btrim(lower(body))"})}$})
      end
    end


    it "should not define :case_sensitive => false with non-trivial expression" do
      with_index Post, :name => "posts_user_body_index", :expression => "BTRIM(LOWER(body))" do
        dump_posts.should match(%r{#{to_regexp(%q{t.index :name => "posts_user_body_index", :expression => "btrim(lower(body))"})}$})
      end
    end


    it "should define kind" do
      with_index Post, :name => "posts_body_index", :expression => "USING hash (body)" do
        dump_posts.should match(to_regexp(%q{t.index ["body"], :name => "posts_body_index", :kind => "hash"}))
      end
    end

    it "should not include index order for non-ordered index types" do
      with_index Post, :user_id, :kind => :hash do
        dump_posts.should match(to_regexp(%q{t.index ["user_id"], :name => "index_posts_on_user_id", :kind => "hash"}))
        dump_posts.should_not match(%r{:order})
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
        expect { dump_schema }.to_not raise_error
      end

      it "should dump constraints after the tables they reference" do
        dump_schema.should match(%r{create_table "comments".*foreign_key.*\["first_comment_id"\], "comments", \["id"\]}m)
        dump_schema.should match(%r{create_table "posts".*foreign_key.*\["first_post_id"\], "posts", \["id"\]}m)
        dump_schema.should match(%r{create_table "posts".*foreign_key.*\["post_id"\], "posts", \["id"\]}m)
        dump_schema.should match(%r{create_table "users".*foreign_key.*\["commenter_id"\], "users", \["id"\]}m)
        dump_schema.should match(%r{create_table "users".*foreign_key.*\["user_id"\], "users", \["id"\]}m)
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

  def with_foreign_key(model, columns, referenced_table_name, referenced_columns, options = {}, &block)
    with_foreign_keys(model, [[columns, referenced_table_name, referenced_columns, options]], &block)
  end

  def with_foreign_keys(model, columnsets)
    table_columns = model.columns.reject{|column| column.name == 'id'}
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table model.table_name, :force => true do |t|
        table_columns.each do |column|
          t.column column.name, column.type
        end
        columnsets.each do |columns, referenced_table_name, referenced_columns, options|
          t.foreign_key columns, referenced_table_name, referenced_columns, options || {}
        end
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
    name ||= model.indexes.detect { |index| index.table == model.table_name.to_s && index.columns.sort == Array(columns).collect(&:to_s).sort }.name
    name
  end

  def determine_foreign_key_name(model, columns, options)
    name = options[:name] 
    name ||= model.foreign_keys.detect { |fk| fk.table_name == model.table_name.to_s && fk.column_names == Array(columns).collect(&:to_s) }.name
  end

  def dump_schema(opts={})
    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = Array.wrap(opts[:ignore]) || []
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end

  def dump_posts
    dump_schema(:ignore => %w[users comments])
  end

end
