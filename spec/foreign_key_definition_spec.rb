require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Foreign Key definition" do

  let(:definition) { SchemaPlus::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new("posts_user_fkey", :posts, :user, :users, :id) }

  it "dumps to sql with quoted values" do
    definition.to_sql.should == %Q{CONSTRAINT posts_user_fkey FOREIGN KEY (#{quote_column_name('user')}) REFERENCES #{quote_table_name('users')} (#{quote_column_name('id')})}
  end

  it "dumps to sql with deferrable values" do
    deferred_definition = SchemaPlus::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new("posts_user_fkey", :posts, :user, :users, :id, nil, nil, true)
    deferred_definition.to_sql.should == %Q{CONSTRAINT posts_user_fkey FOREIGN KEY (#{quote_column_name('user')}) REFERENCES #{quote_table_name('users')} (#{quote_column_name('id')}) DEFERRABLE}
  end

  it "dumps to sql with initially deferrable values" do
    initially_deferred_definition = SchemaPlus::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new("posts_user_fkey", :posts, :user, :users, :id, nil, nil, :initially_deferred)
    initially_deferred_definition.to_sql.should == %Q{CONSTRAINT posts_user_fkey FOREIGN KEY (#{quote_column_name('user')}) REFERENCES #{quote_table_name('users')} (#{quote_column_name('id')}) DEFERRABLE INITIALLY DEFERRED}
  end

  def quote_table_name(table)
    ActiveRecord::Base.connection.quote_table_name(table)
  end

  def quote_column_name(column)
    ActiveRecord::Base.connection.quote_column_name(column)
  end

end
