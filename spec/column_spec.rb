require 'spec_helper'

describe "Column" do

  before(:all) do
      class User < ::ActiveRecord::Base ; end
  end
    
  let(:migration) { ::ActiveRecord::Migration }

  context "regarding when it requires a value" do

    it "not required if the column can be null" do
      create_table(User, :login => { :null => true})
      expect(User.columns.find{|column| column.name == "login"}.required_on).to be_nil
    end

    it "must have a value on :save if there's no default" do
      create_table(User, :login => { :null => false })
      expect(User.columns.find{|column| column.name == "login"}.required_on).to eq(:save)
    end

    it "must have a value on :update if there's default" do
      create_table(User, :login => { :null => false, :default => "foo" })
      expect(User.columns.find{|column| column.name == "login"}.required_on).to eq(:update)
    end

  end

  protected

  def create_table(model, columns_with_options)
    migration.suppress_messages do
      migration.create_table model.table_name, :force => true do |t|
        columns_with_options.each_pair do |column, options|
          t.send :string, column, options
        end
      end
      model.reset_column_information
    end
  end

end
