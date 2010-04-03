# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ActiveRecord::Base do

  it "should respond to references" do
    ActiveRecord::Base.should respond_to :references
  end

end

describe ActiveRecord::Migration do

  context "with column references other column" do

    before(:all) do
      @migration = ActiveRecord::Migration
    end

    it "should receive add_foreign_key" do
      @migration.should_receive(:add_foreign_key)
      add_column(:comments, :post_id, :integer)
    end

    it "shouldn't receive add_foreign_key if column doesn't look like foreign key" do
      @migration.should_not_receive(:add_foreign_key)
      add_column(:comments, :views_count, :integer)
    end

    it "shouldnt't receive add_foreign_key if specified explicity" do
      @migration.should_not_receive(:add_foreign_key)
      add_column(:comments, :post_id, :integer, :references => nil)
    end

    def add_column(table, column_name, *args)
      @migration.suppress_messages do
        @migration.add_column(table, column_name, *args)
        yield if block_given?
        @migration.remove_column(table, column_name)
      end
    end

  end

end

