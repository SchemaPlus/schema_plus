require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'stringio'

require 'models/post'

describe "Schema dump" do

  let(:dump) do
    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = []
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end

  unless ActiveRecord::Base.connection.adapter_name =~ /^sqlite/i
    it "shouldn't include :index option for index" do
      add_column(:author_id, :integer, :references => :users, :index => true) do
        dump.should_not match(/index => true/)
      end
    end
  end
    
  protected
  def add_column(column_name, *args)
    table = Post.table_name
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.add_column(table, column_name, *args)
      Post.reset_column_information
      yield if block_given?
      ActiveRecord::Migration.remove_column(table, column_name)
    end
  end

end
