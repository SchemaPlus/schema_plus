# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'references method' do

  before(:all) do
    @target = ActiveRecord::Base
    @table_name = 'comments'
    @column_name = 'post_id'
    @destination_table = 'posts'
    @destinantion_column = :id
  end

  it "should accept table name and column name to references" do
    lambda { @target.references(@table_name, @column_name) }.should_not raise_error
  end

  it "should return an array" do
    @target.references(@table_name, @column_name).should be_an(Array)
  end

  it "should split column name to table name and primary key" do
    result = @target.references(@table_name, @column_name)
    result[0].should eql @destination_table
    result[1].should eql @destinantion_column
  end

  it "should handle parent_id as belonging to the same table" do
    column_name = 'parent_id'
    result = @target.references(@table_name, column_name)
    result[0].should eql @table_name
    result[1].should eql :id
  end

  it "should accept :references option which overrides default table name" do
    result = @target.references(@table_name, @column_name, :references => 'users')
    result[0].should eql 'users'
    result[1].should eql :id
  end

  it "should accept :references option which overrides default table name and default column name" do
    result = @target.references(@table_name, @column_name, :references => ['users', 'uuid'])
    result[0].should eql 'users'
    result[1].should eql 'uuid'
  end

end

