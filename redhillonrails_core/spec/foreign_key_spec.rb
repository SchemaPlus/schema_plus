require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/user'
require 'models/post'
require 'models/comment'

describe "Foreign Key" do

  let(:migration) { ActiveRecord::Migration }

  context "when is added", "posts(author_id)" do

    before(:each) do 
      add_foreign_key(:posts, :author_id, :users, :id, :on_update => :cascade, :on_delete => :restrict)
    end

    after(:each) do
      fk = Post.foreign_keys.detect { |fk| fk.column_names == %w[author_id] }
      remove_foreign_key(:posts, fk.name)
    end

    it "references users(id)" do
      Post.should reference(:users, :id).on(:author_id)
    end

    it "cascades on update" do
      Post.should reference(:users).on_update(:cascade)
    end

    it "restricts on delete" do
      Post.should reference(:users).on_delete(:restrict)
    end

    it "is available in Post.foreign_keys" do
      Post.foreign_keys.collect(&:column_names).should include(%w[author_id])
    end

    it "is available in User.reverse_foreign_keys" do
      User.reverse_foreign_keys.collect(&:column_names).should include(%w[author_id])
    end

  end

  context "when is dropped", "comments(post_id)" do

    let(:foreign_key_name) { Comment.foreign_keys.detect { |definition| definition.column_names == %w[post_id] }.name }

    before(:each) do
      remove_foreign_key(:comments, foreign_key_name)
    end

    after(:each) do
      add_foreign_key(:comments, :post_id, :posts, :id)
    end

    it "doesn't reference posts(id)" do
      Comment.should_not reference(:posts).on(:post_id)
    end

    it "is no longer available in Post.foreign_keys" do
      Comment.foreign_keys.collect(&:column_names).should_not include(%w[post_id])
    end
    
    it "is no longer available in User.reverse_foreign_keys" do
      Post.reverse_foreign_keys.collect(&:column_names).should_not include(%w[post_id])
    end

  end

  context "when referencing column and column is removed" do

    let(:foreign_key_name) { Comment.foreign_keys.detect { |definition| definition.column_names == %w[post_id] }.name }

    it "should remove foreign keys" do
      remove_foreign_key(:comments, foreign_key_name)
      Post.reverse_foreign_keys.collect { |fk| fk.column_names == %w[post_id] && fk.table_name == "comments" }.should be_empty
    end

  end

  protected
  def add_foreign_key(*args)
    migration.suppress_messages do
      migration.add_foreign_key(*args)
    end
    User.reset_column_information
    Post.reset_column_information
    Comment.reset_column_information
  end

  def remove_foreign_key(*args)
    migration.suppress_messages do
      migration.remove_foreign_key(*args)
    end
    User.reset_column_information
    Post.reset_column_information
    Comment.reset_column_information
  end

end
