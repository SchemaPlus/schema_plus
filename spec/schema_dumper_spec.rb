require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'stringio'

require 'models/post'

describe "Schema dump (core)" do

  before(:all) do
    load_core_schema
  end

  let(:dump) do
    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = %w[users comments]
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end

  it "should include foreign_key definition" do
    with_foreign_key Post, :user_id, :users, :id do
      dump.should match(to_regexp(%q{t.foreign_key ["user_id"], "users", ["id"]}))
    end
  end

  it "should include foreign_key options" do
    with_foreign_key Post, :user_id, :users, :id, :on_update => :cascade, :on_delete => :set_null do
      dump.should match(to_regexp(%q{t.foreign_key ["user_id"], "users", ["id"], :on_update => :cascade, :on_delete => :set_null}))
    end
  end

  it "should include index definition" do
    with_index Post, :user_id do
      dump.should match(to_regexp(%q{t.index ["user_id"]}))
    end
  end

  it "should include index name" do
    with_index Post, :user_id, :name => "posts_user_id_index" do
      dump.should match(to_regexp(%q{t.index ["user_id"], :name => "posts_user_id_index"}))
    end
  end
  
  it "should define unique index" do
    with_index Post, :user_id, :name => "posts_user_id_index", :unique => true do
      dump.should match(to_regexp(%q{t.index ["user_id"], :name => "posts_user_id_index", :unique => true}))
    end
  end

  if SchemaPlusHelpers.postgresql?

    it "should define case insensitive index" do
      with_index Post, :name => "posts_user_body_index", :expression => "USING btree (LOWER(body))" do
        dump.should match(to_regexp(%q{t.index ["body"], :name => "posts_user_body_index", :case_sensitive => false}))
      end
    end

    it "should define conditions" do
      with_index Post, :user_id, :name => "posts_user_id_index", :conditions => "user_id IS NOT NULL" do
        dump.should match(to_regexp(%q{t.index ["user_id"], :name => "posts_user_id_index", :conditions => "(user_id IS NOT NULL)"}))
      end
    end

    it "should define expression" do
      with_index Post, :name => "posts_freaky_index", :expression => "USING hash (least(id, user_id))" do
        dump.should match(to_regexp(%q{t.index :name => "posts_freaky_index", :kind => "hash", :expression => "LEAST(id, user_id)"}))
      end
    end

    it "should define kind" do
      with_index Post, :name => "posts_body_index", :expression => "USING hash (body)" do
        dump.should match(to_regexp(%q{t.index ["body"], :name => "posts_body_index", :kind => "hash"}))
      end
    end

  end

  protected
  def to_regexp(string)
    Regexp.new(Regexp.escape(string))
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

describe "Schema dump (auto)" do
  
  before(:all) do
    load_auto_schema
  end

  let(:dump) do
    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = []
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end

  unless SchemaPlusHelpers.sqlite3?
    it "shouldn't include :index option for index" do
      add_column(:author_id, :integer, :references => :users, :index => true) do
        dump.should_not match(/index => true/)
      end
    end
  end
    
  protected
  def add_column(column_name, *args)
    table = Post.table_name
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.add_column(table, column_name, *args)
      Post.reset_column_information
      yield if block_given?
      ActiveRecord::Migration.remove_column(table, column_name)
    end
  end

end

