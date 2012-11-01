require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Foreign Key definition" do

  before(:all) do
    create_schema do
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
        t.foreign_key :post_id, :posts, :id
      end
    end
  end

  let(:definition) { SchemaPlus::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new("posts_user_fkey", :posts, :user, :users, :id) }

  it "it is dumped to sql with quoted values" do
    definition.to_sql.should == %Q{CONSTRAINT posts_user_fkey FOREIGN KEY (#{quote_column_name('user')}) REFERENCES #{quote_table_name('users')} (#{quote_column_name('id')})}
  end

  def quote_table_name(table)
    ActiveRecord::Base.connection.quote_table_name(table)
  end

  def quote_column_name(column)
    ActiveRecord::Base.connection.quote_column_name(column)
  end

end
