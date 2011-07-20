require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/user'
require 'models/post'
require 'models/comment'

describe "Foreign Key" do
  
  let(:migration) { ::ActiveRecord::Migration }

  context "created with table" do
    before(:all) do
      load_auto_schema
    end

    it "should report foreign key constraints" do
      Comment.foreign_keys.collect(&:column_names).flatten.should == [ "user_id" ]
    end

    it "should report reverse foreign key constraints" do
      User.reverse_foreign_keys.collect(&:column_names).flatten.should == [ "user_id" ]
    end

  end

  context "modification" do

    before(:all) do
      load_core_schema
    end

    if SchemaPlusHelpers.sqlite3?

      it "raises an exception when attempting to add" do
        expect { 
          add_foreign_key(:posts, :author_id, :users, :id, :on_update => :cascade, :on_delete => :restrict)
        }.should raise_error(NotImplementedError)
      end

      it "raises an exception when attempting to remove" do
        expect { 
          remove_foreign_key(:posts, "dummy")
        }.should raise_error(NotImplementedError)
      end

    else

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

        let(:foreign_key_name) { fk = Comment.foreign_keys.detect { |definition| definition.column_names == %w[post_id] } and fk.name }

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

      context "when table name is a rerved word" do
        before(:each) do
          migration.suppress_messages do
            migration.create_table :references, :force => true do |t|
              t.integer :post_id
            end
          end
        end

        it "can add, detect, and remove a foreign key without error" do
          migration.suppress_messages do
            expect {
              migration.add_foreign_key(:references, :post_id, :posts, :id)
              foreign_key = migration.foreign_keys(:references).detect{|definition| definition.column_names == ["post_id"]}
              migration.remove_foreign_key(:references, foreign_key.name)
            }.should_not raise_error
          end
        end
      end

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
