# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/post'
require 'models/comment'

describe ActiveRecord::Base do

  it "should respond to references" do
    ActiveRecord::Base.should respond_to :references
  end

end

describe ActiveRecord::Migration do

  context "when table is created" do
    it "should create foreign keys" do
      create_table(Post,  :user_id => {}, 
                          :author_id => { :references => :users },
                          :member_id => { :references => nil } )
      Post.should reference(:users, :id).on(:user_id)
      Post.should reference(:users, :id).on(:author_id)
      Post.should_not reference.on(:member_id)
    end

  end

  context "when column is added" do

    before(:all) do
      @model = Comment
    end

    it "should create foreign key" do
      add_column(:post_id, :integer) do
        @model.should reference(:posts, :id).on(:post_id)
      end
    end

    it "should create foreign key to explicity given table" do
      add_column(:author_id, :integer, :references => :users) do
        @model.should reference(:users, :id).on(:author_id)
      end
    end

    it "should create foreign key to explicity given table and column name" do
      add_column(:author_login, :string, :references => [:users, :login]) do 
        @model.should reference(:users, :login).on(:author_login) 
      end
    end

    it "should create foreign key to the same table on parent_id" do
      add_column(:parent_id, :integer) do
        @model.should reference(@model.table_name, :id).on(:parent_id)
      end
    end

    it "shouldn't create foreign key if column doesn't look like foreign key" do
      add_column(:views_count, :integer) do
        @model.should_not reference.on(:views_count)
      end
    end

    it "shouldnt't create foreign key if specified explicity" do
      add_column(:post_id, :integer, :references => nil) do
        @model.should_not reference.on(:post_id)
      end
    end

    def add_column(column_name, *args)
      table = @model.table_name
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.add_column(table, column_name, *args)
        @model.reset_column_information
        yield if block_given?
        ActiveRecord::Migration.remove_column(table, column_name)
      end
    end

  end
    
  def foreign_key(model, column)
    columns = Array(column)
    model.foreign_keys.detect { |fk| fk.table_name == model.table_name && fk.column_names == columns } 
  end
  
  def create_table(model, columns_with_options)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table model.table_name, :force => true do |t|
        columns_with_options.each_pair do |column, options|
          t.integer column, options
        end
      end
      model.reset_column_information
    end
  end

end

