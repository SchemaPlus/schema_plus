require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/user'

describe "Foreign Key definition" do

  let(:definition) { RedhillonrailsCore::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new("posts_user_fkey", :posts, :user, :users, :id) }

  it "it is dumped to sql with quoted values" do
    definition.to_sql.should == %Q{CONSTRAINT #{quote('posts_user_fkey')} FOREIGN KEY (#{quote_column_name('user')}) REFERENCES #{quote_table_name('users')} (#{quote_column_name('id')})}
  end

  def quote_table_name(table)
    ActiveRecord::Base.connection.quote_table_name(table)
  end

  def quote_column_name(column)
    ActiveRecord::Base.connection.quote_column_name(column)
  end

  def quote(name)
    ActiveRecord::Base.connection.quote(name)
  end

end
