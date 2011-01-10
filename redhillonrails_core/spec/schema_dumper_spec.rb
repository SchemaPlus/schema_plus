require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'stringio'

require 'models/post'

describe "Schema dump" do

  let(:dump) do
    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = %w[users comments]
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end

  it "should include foreign_key definition" do
    with_foreign_key Post, :user_id, :users, :id do
      dump.should match(to_regexp(%q{add_foreign_key "posts", ["user_id"], "users", ["id"]}))
    end
  end

  unless ::ActiveRecord::Base.connection.class.include?(RedhillonrailsCore::ActiveRecord::ConnectionAdapters::Sqlite3Adapter)

    it "should include foreign_key options" do
      with_foreign_key Post, :user_id, :users, :id, :on_update => :cascade, :on_delete => :set_null do
        dump.should match(to_regexp(%q{add_foreign_key "posts", ["user_id"], "users", ["id"], :on_update => :cascade, :on_delete => :set_null}))
      end
    end

  end

  it "should include index definition" do
    with_index Post, :user_id do
      dump.should match(to_regexp(%q{add_index "posts", ["user_id"]}))
    end
  end

  it "should include index name" do
    with_index Post, :user_id, :name => "posts_user_id_index" do
      dump.should match(to_regexp(%q{add_index "posts", ["user_id"], :name => "posts_user_id_index"}))
    end
  end
  
  it "should define unique index" do
    with_index Post, :user_id, :name => "posts_user_id_index", :unique => true do
      dump.should match(to_regexp(%q{add_index "posts", ["user_id"], :name => "posts_user_id_index", :unique => true}))
    end
  end
  
  if ::ActiveRecord::Base.connection.class.include?(RedhillonrailsCore::ActiveRecord::ConnectionAdapters::PostgresqlAdapter)

  it "should define case insensitive index" do
    with_index Post, :name => "posts_user_body_index", :expression => "USING btree (LOWER(body))" do
      dump.should match(to_regexp(%q{add_index "posts", ["body"], :name => "posts_user_body_index", :case_sensitive => false}))
    end
  end

  it "should define conditions" do
    with_index Post, :user_id, :name => "posts_user_id_index", :conditions => "user_id IS NOT NULL" do
      dump.should match(to_regexp(%q{add_index "posts", ["user_id"], :name => "posts_user_id_index", :conditions => "(user_id IS NOT NULL)"}))
    end
  end

  it "should define expression" do
    with_index Post, :name => "posts_freaky_index", :expression => "USING hash (least(id, user_id))" do
      dump.should match(to_regexp(%q{add_index "posts", :name => "posts_freaky_index", :kind => "hash", :expression => "LEAST(id, user_id)"}))
    end
  end
  
  it "should define kind" do
    with_index Post, :name => "posts_body_index", :expression => "USING hash (body)" do
      dump.should match(to_regexp(%q{add_index "posts", ["body"], :name => "posts_body_index", :kind => "hash"}))
    end
  end

  end # of postgresql specific examples

  protected
  def to_regexp(string)
    Regexp.new(Regexp.escape(string))
  end

  def with_foreign_key(model, columns, referenced_table_name, referenced_columns, options = {})
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.add_foreign_key(model.table_name, columns, referenced_table_name, referenced_columns, options)
    end
    model.reset_column_information
    yield
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.remove_foreign_key(model.table_name, determine_foreign_key_name(model, columns, options))
    end
  end
  
  def with_index(model, columns, options = {})
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.add_index(model.table_name, columns, options)
    end
    model.reset_column_information
    yield
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.remove_index(model.table_name, :name => determine_index_name(model, columns, options))
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
