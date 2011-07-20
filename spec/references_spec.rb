# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'get_references method' do

  before(:all) do
    @target = ActiveRecord::Migration
    @table_name = 'comments'
    @column_name = 'post_id'
    @destination_table = 'posts'
    @destinantion_column = :id
  end

  around(:each) do |example|
    with_auto_create do
      example.run
    end
  end

  it "should accept table name and column name to references" do
    lambda { @target.get_references(@table_name, @column_name) }.should_not raise_error
  end

  it "should return an array" do
    @target.get_references(@table_name, @column_name).should be_an(Array)
  end

  it "should return nil if auto_create is disabled" do
    SchemaPlus.config.foreign_keys.auto_create = false
    @target.get_references(@table_name, @column_name).should be_nil
  end

  it "should split column name to table name and primary key" do
    result = @target.get_references(@table_name, @column_name)
    result[0].should eql @destination_table
    result[1].should eql @destinantion_column
  end

  it "should not auto create referencs when configured not to" do
    with_auto_create(false) do
      result = @target.get_references(@table_name, @column_name)
      result.should be_nil
    end
  end

  it "should handle parent_id as belonging to the same table" do
    column_name = 'parent_id'
    result = @target.get_references(@table_name, column_name)
    result[0].should eql @table_name
    result[1].should eql :id
  end

  it "should accept :references option which overrides default table name" do
    result = @target.get_references(@table_name, @column_name, :references => 'users')
    result[0].should eql 'users'
    result[1].should eql :id
  end

  it "should accept :references option which overrides default table name and default column name" do
    result = @target.get_references(@table_name, @column_name, :references => ['users', 'uuid'])
    result[0].should eql 'users'
    result[1].should eql 'uuid'
  end

  protected

  def with_auto_create(value = true)
    old_value = SchemaPlus.config.foreign_keys.auto_create
    SchemaPlus.config.foreign_keys.auto_create = value
    begin
      yield
    ensure
      SchemaPlus.config.foreign_keys.auto_create = old_value
    end
  end

end

