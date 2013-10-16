require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe "Check constraints" do
  before(:all) do
    define_schema(:auto_create => false) do
      create_table :posts, :force => true do |t|
        t.text :body
        t.string :post_type
        t.string :post_type2
        t.string :post_type3
      end
    end
    class Post < ::ActiveRecord::Base ; end
  end

  def call_add_column_check_constraint(*params)
    ActiveRecord::Base.connection.add_column_check_constraint(*params)
  end

  if SchemaPlusHelpers.mysql?

    it "should silently skip constraint definition" do
      call_add_column_check_constraint(:posts, :post_type, ["a", "b", "c"])

      post = Post.create!(body: "body", post_type: "a")
      post.post_type.should == "a"
      post = Post.create!(body: "body", post_type: "z")
      post.post_type.should == "z"
    end

  else

    it "should generate check constraint for array of possible values" do
      call_add_column_check_constraint(:posts, :post_type, ["a", "b", "c"])

      post = Post.create!(body: "body", post_type: "a")
      post.post_type.should == "a"

      expect { Post.create!(body: "body", post_type: "d") }.to raise_error
      expect { Post.create!(body: "body", post_type: 1) }.to raise_error
    end

    it "should use string as check constraint expression" do
      call_add_column_check_constraint(:posts, :post_type2, "post_type2 = 'foo'")

      post = Post.create!(body: "body", post_type2: "foo")
      post.post_type2.should == "foo"
    end

    it "should break given wrong constraint" do
      expect { call_add_column_check_constraint(:posts, :post_type3, {:foo => :bar}) }.to raise_error("Invalid column 'post_type3' check constraint in table 'posts'.")
    end

  end

end
