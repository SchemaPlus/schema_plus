require 'spec_helper'
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
      expect(dump_posts).to match(to_regexp(%q{t.foreign_key ["user_id"], "users", ["id"]}))
    end
  end

  it "should include foreign_key name" do
    with_foreign_key Post, :user_id, :users, :id, :name => "yippee" do
      expect(dump_posts).to match(/foreign_key.*user_id.*users.*id.*:name => "yippee"/)
    end
  end

  it "should include foreign_key exactly once" do
    with_foreign_key Post, :user_id, :users, :id, :name => "yippee" do
      expect(dump_posts.scan(/foreign_key.*yippee"/).length).to eq 1
    end
  end


  it "should sort foreign_key definitions" do
    with_foreign_keys Comment, [ [ :post_id, :posts, :id ], [ :commenter_id, :users, :id ]] do
      expect(dump_schema).to match(/foreign_key.+commenter_id.+foreign_key.+post_id/m)
    end
  end

  context "with constraint dependencies" do
    it "should sort in Posts => Comments direction" do
      with_foreign_key Comment, :post_id, :posts, :id do
        expect(dump_schema).to match(%r{create_table "posts".*create_table "comments"}m)
      end
    end
    it "should sort in Comments => Posts direction" do
      with_foreign_key Post, :first_comment_id, :comments, :id do
        expect(dump_schema).to match(%r{create_table "comments".*create_table "posts"}m)
      end
    end

    it "should handle regexp in ignore_tables" do
      with_foreign_key Comment, :post_id, :posts, :id do
        dump = dump_schema(:ignore => /post/)
        expect(dump).to match(/create_table "comments"/)
        expect(dump).not_to match(/create_table "posts"/)
      end
    end

  end

  it "should include foreign_key options" do
    with_foreign_key Post, :user_id, :users, :id, :on_update => :cascade, :on_delete => :set_null do
      expect(dump_posts).to match(to_regexp(%q{t.foreign_key ["user_id"], "users", ["id"], :on_update => :cascade, :on_delete => :set_null}))
    end
  end

  context "with cyclic foreign key constraints", :sqlite3 => :skip do
    before(:all) do
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
      expect(dump_schema).to match(%r{create_table "comments".*foreign_key.*\["first_comment_id"\], "comments", \["id"\]}m)
      expect(dump_schema).to match(%r{create_table "posts".*foreign_key.*\["first_post_id"\], "posts", \["id"\]}m)
      expect(dump_schema).to match(%r{create_table "posts".*foreign_key.*\["post_id"\], "posts", \["id"\]}m)
      expect(dump_schema).to match(%r{create_table "users".*foreign_key.*\["commenter_id"\], "users", \["id"\]}m)
      expect(dump_schema).to match(%r{create_table "users".*foreign_key.*\["user_id"\], "users", \["id"\]}m)
    end
  end

  protected
  def to_regexp(string)
    Regexp.new(Regexp.escape(string))
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
