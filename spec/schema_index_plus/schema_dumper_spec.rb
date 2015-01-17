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

  it "should include index definition" do
    with_index Post, :user_id do
      expect(dump_posts).to match(to_regexp(%q{t.index ["user_id"]}))
    end
  end

  it "should include index name" do
    with_index Post, :user_id, :name => "custom_name" do
      expect(dump_posts).to match(to_regexp(%q{t.index ["user_id"], :name => "custom_name"}))
    end
  end
  
  it "should define unique index" do
    with_index Post, :user_id, :name => "posts_user_id_index", :unique => true do
      expect(dump_posts).to match(to_regexp(%q{t.index ["user_id"], :name => "posts_user_id_index", :unique => true}))
    end
  end

  it "should sort indexes" do
    with_index Post, :user_id do
      with_index Post, :short_id do
        expect(dump_posts).to match(/on_short_id.+on_user_id/m)
      end
    end
  end

  it "should include index order", :mysql => :skip do
    with_index Post, [:user_id, :first_comment_id, :short_id], :order => { :user_id => :asc, :first_comment_id => :desc } do
      expect(dump_posts).to match(%r{t.index \["user_id", "first_comment_id", "short_id"\],.*:order => {"user_id" => :asc, "first_comment_id" => :desc, "short_id" => :asc}})
    end
  end

  context "index extras", :postgresql => :only do

    it "should define case insensitive index" do
      with_index Post, [:body, :string_no_default], :case_sensitive => false do
        expect(dump_posts).to match(to_regexp(%q{t.index ["body", "string_no_default"], :name => "index_posts_on_body_and_string_no_default", :case_sensitive => false}))
      end
    end

    it "should define index with type cast" do
      with_index Post, [:integer_col], :name => "index_with_type_cast", :expression => "LOWER(integer_col::text)" do
        expect(dump_posts).to match(to_regexp(%q{t.index :name => "index_with_type_cast", :expression => "lower((integer_col)::text)"}))
      end
    end


    it "should define case insensitive index with mixed ids and strings" do
      with_index Post, [:user_id, :str_short, :short_id, :body], :case_sensitive => false do
        expect(dump_posts).to match(to_regexp(%q{t.index ["user_id", "str_short", "short_id", "body"], :name => "index_posts_on_user_id_and_str_short_and_short_id_and_body", :case_sensitive => false}))
      end
    end

    [:integer, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean].each do |col_type|
      col_name = "#{col_type}_col"
      it "should define case insensitive index that includes an #{col_type}" do
        with_index Post, [:user_id, :str_short, col_name, :body], :case_sensitive => false do
          expect(dump_posts).to match(to_regexp(%Q!t.index ["user_id", "str_short", "#{col_name}", "body"], :name => "index_posts_on_user_id_and_str_short_and_#{col_name}_and_body", :case_sensitive => false!))
        end
      end
    end

    it "should define where" do
      with_index Post, :user_id, :name => "posts_user_id_index", :where => "user_id IS NOT NULL" do
        expect(dump_posts).to match(to_regexp(%q{t.index ["user_id"], :name => "posts_user_id_index", :where => "(user_id IS NOT NULL)"}))
      end
    end

    it "should define expression" do
      with_index Post, :name => "posts_freaky_index", :expression => "USING hash (least(id, user_id))" do
        expect(dump_posts).to match(to_regexp(%q{t.index :name => "posts_freaky_index", :using => "hash", :expression => "LEAST(id, user_id)"}))
      end
    end

    it "should define operator_class" do
      with_index Post, :body, :operator_class => 'text_pattern_ops' do
        expect(dump_posts).to match(to_regexp(%q{t.index ["body"], :name => "index_posts_on_body", :operator_class => {"body" => "text_pattern_ops"}}))
      end
    end

    it "should dump unique: true with expression (Issue #142)" do
      with_index Post, :name => "posts_user_body_index", :unique => true, :expression => "BTRIM(LOWER(body))" do
        expect(dump_posts).to match(%r{#{to_regexp(%q{t.index :name => "posts_user_body_index", :unique => true, :expression => "btrim(lower(body))"})}$})
      end
    end


    it "should not define :case_sensitive => false with non-trivial expression" do
      with_index Post, :name => "posts_user_body_index", :expression => "BTRIM(LOWER(body))" do
        expect(dump_posts).to match(%r{#{to_regexp(%q{t.index :name => "posts_user_body_index", :expression => "btrim(lower(body))"})}$})
      end
    end

    it "should define using" do
      with_index Post, :name => "posts_body_index", :expression => "USING hash (body)" do
        expect(dump_posts).to match(to_regexp(%q{t.index ["body"], :name => "posts_body_index", :using => "hash"}))
      end
    end

    it "should not include index order for non-ordered index types" do
      with_index Post, :user_id, :using => :hash do
        expect(dump_posts).to match(to_regexp(%q{t.index ["user_id"], :name => "index_posts_on_user_id", :using => "hash"}))
        expect(dump_posts).not_to match(%r{:order})
      end
    end

  end

  protected

  def to_regexp(string)
    Regexp.new(Regexp.escape(string))
  end

  def with_index(*args)
    options = args.extract_options!
    model, columns = args
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

