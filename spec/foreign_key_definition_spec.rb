require 'spec_helper'

describe "Foreign Key definition" do

  let(:definition) {
    options = {:name => "posts_user_fkey", :column => :user, :primary_key => :id}
    ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(:posts, :users, options)
  }

  it "dumps to sql with quoted values" do
    expect(definition.to_sql).to eq(%Q{CONSTRAINT posts_user_fkey FOREIGN KEY (#{quote_column_name('user')}) REFERENCES #{quote_table_name('users')} (#{quote_column_name('id')})})
  end

  it "dumps to sql with deferrable values" do
    options = {:name => "posts_user_fkey", :column => :user, :primary_key => :id, :deferrable => true}
    deferred_definition = ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(:posts, :users, options)
    expect(deferred_definition.to_sql).to eq(%Q{CONSTRAINT posts_user_fkey FOREIGN KEY (#{quote_column_name('user')}) REFERENCES #{quote_table_name('users')} (#{quote_column_name('id')}) DEFERRABLE})
  end

  it "dumps to sql with initially deferrable values" do
    options = {:name => "posts_user_fkey", :column => :user, :primary_key => :id, :deferrable => :initially_deferred}
    initially_deferred_definition = ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(:posts, :users, options)
    expect(initially_deferred_definition.to_sql).to eq(%Q{CONSTRAINT posts_user_fkey FOREIGN KEY (#{quote_column_name('user')}) REFERENCES #{quote_table_name('users')} (#{quote_column_name('id')}) DEFERRABLE INITIALLY DEFERRED})
  end

  def quote_table_name(table)
    ActiveRecord::Base.connection.quote_table_name(table)
  end

  def quote_column_name(column)
    ActiveRecord::Base.connection.quote_column_name(column)
  end

end
