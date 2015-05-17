require 'spec_helper'

describe "Foreign Key" do

  let(:migration) { ::ActiveRecord::Migration }

  context "created with table" do
    before(:all) do
      define_schema(:auto_create => true) do
        create_table :users, :force => true do |t|
          t.string :login
        end
        create_table :comments, :force => true do |t|
          t.integer :user_id
          t.foreign_key :user_id, :users
        end
      end
      class User < ::ActiveRecord::Base ; end
      class Comment < ::ActiveRecord::Base ; end
    end

    it "should report foreign key constraints" do
      expect(Comment.foreign_keys.collect(&:column).flatten).to eq([ "user_id" ])
    end

    it "should report reverse foreign key constraints" do
      expect(User.reverse_foreign_keys.collect(&:column).flatten).to eq([ "user_id" ])
    end

  end

  context "modification" do

    before(:each) do
      define_schema(:auto_create => false) do
        create_table :users, :force => true do |t|
          t.string :login
          t.datetime :deleted_at
        end

        create_table :posts, :force => true do |t|
          t.text :body
          t.integer :user_id
          t.integer :author_id
        end

        create_table :comments, :force => true do |t|
          t.text :body
          t.integer :post_id
          t.foreign_key :post_id, :posts
        end
      end
      class User < ::ActiveRecord::Base ; end
      class Post < ::ActiveRecord::Base ; end
      class Comment < ::ActiveRecord::Base ; end
      Comment.reset_column_information
    end


    context "works", :sqlite3 => :skip do

      context "when is added", "posts(author_id)" do

        before(:each) do
          add_foreign_key(:posts, :users, :column => :author_id, :on_update => :cascade, :on_delete => :restrict)
        end

        it "references users(id)" do
          expect(Post).to reference(:users, :id).on(:author_id)
        end

        it "cascades on update" do
          expect(Post).to reference(:users).on_update(:cascade)
        end

        it "restricts on delete" do
          expect(Post).to reference(:users).on_delete(:restrict)
        end

        it "is available in Post.foreign_keys" do
          expect(Post.foreign_keys.collect(&:column)).to include('author_id')
        end

        it "is available in User.reverse_foreign_keys" do
          expect(User.reverse_foreign_keys.collect(&:column)).to include('author_id')
        end

      end

      context "when is dropped", "comments(post_id)" do

        let(:foreign_key_name) { fk = Comment.foreign_keys.detect(&its.column == 'post_id') and fk.name }

        before(:each) do
          remove_foreign_key(:comments, name: foreign_key_name)
        end

        it "doesn't reference posts(id)" do
          expect(Comment).not_to reference(:posts).on(:post_id)
        end

        it "is no longer available in Post.foreign_keys" do
          expect(Comment.foreign_keys.collect(&:column)).not_to include('post_id')
        end

        it "is no longer available in User.reverse_foreign_keys" do
          expect(Post.reverse_foreign_keys.collect(&:column)).not_to include('post_id')
        end

      end

      context "when drop using hash", "comments(post_id)" do

        let(:foreign_key_name) { fk = Comment.foreign_keys.detect(&its.column == 'post_id') and fk.name }

        it "finds by name" do
          remove_foreign_key(:comments, name: foreign_key_name)
          expect(Comment).not_to reference(:posts).on(:post_id)
        end

        it "finds by column_names" do
          remove_foreign_key(:comments, column: "post_id", to_table: "posts")
          expect(Comment).not_to reference(:posts).on(:post_id)
        end
      end

      context "when attempt to drop nonexistent foreign key" do
        it "raises error" do
          expect{remove_foreign_key(:comments, "posts", column: "nonesuch")}.to raise_error(/no foreign key/i)
        end

        it "does not error with :if_exists" do
          expect{remove_foreign_key(:comments, "posts", column: "nonesuch", :if_exists => true)}.to_not raise_error
        end
      end

      context "when referencing column and column is removed" do

        let(:foreign_key_name) { Comment.foreign_keys.detect { |definition| definition.column == 'post_id' }.name }

        it "should remove foreign keys" do
          remove_foreign_key(:comments, name: foreign_key_name)
          expect(Post.reverse_foreign_keys.collect { |fk| fk.column == 'post_id' && fk.from_table == "comments" }).to be_empty
        end

      end

      context "when table name is a reserved word" do
        before(:each) do
          migration.suppress_messages do
            migration.create_table :references, :force => true do |t|
              t.integer :post_id, :foreign_key => false
            end
          end
        end

        it "can add, detect, and remove a foreign key without error" do
          migration.suppress_messages do
            expect {
              migration.add_foreign_key(:references, :posts)
              foreign_key = migration.foreign_keys(:references).detect{|definition| definition.column == "post_id"}
              migration.remove_foreign_key(:references, name: foreign_key.name)
            }.to_not raise_error
          end
        end
      end

    end

    context "raises an exception", :sqlite3 => :only do

      it "when attempting to add" do
        expect {
          add_foreign_key(:posts, :users, :column => :author_id, :on_update => :cascade, :on_delete => :restrict)
        }.to raise_error(NotImplementedError)
      end

      it "when attempting to remove" do
        expect {
          remove_foreign_key(:posts, name: "dummy")
        }.to raise_error(NotImplementedError)
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
