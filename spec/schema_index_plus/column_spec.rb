require 'spec_helper'

describe "Column" do

  before(:all) do
      class User < ::ActiveRecord::Base ; end
  end
    
  let(:migration) { ::ActiveRecord::Migration }

  context "JSON serialization" do
    before(:each) do
      create_table(User, :login => { :index => true})
      @login = User.columns.find{|column| column.name == "login"}
    end
    it "works properly" do
      type = case
             when SchemaDev::Rspec::Helpers.mysql?
               { "sql_type" => "varchar(255)" }
             when SchemaDev::Rspec::Helpers.postgresql?
               { "sql_type" => "character varying" }
             when SchemaDev::Rspec::Helpers.sqlite3?
               { "sql_type" => "varchar" }
             end
      expect(JSON.parse(@login.to_json)).to include(type.merge("name" => "login"))
    end
  end

  context "regarding indexes" do

    context "if not unique" do

      before(:each) do 
        create_table(User, :login => { :index => true})
        @login = User.columns.find{|column| column.name == "login"}
      end

      it "should report not unique" do
        expect(@login).not_to be_unique
      end

      it "should report nil unique scope" do
        create_table(User, :login => { :index => true})
        expect(@login.unique_scope).to be_nil
      end
    end

    context "if unique single column" do
      before(:each) do 
        create_table(User, :login => { :index => :unique})
        @login = User.columns.find{|column| column.name == "login"}
      end

      it "should report unique" do
        expect(@login).to be_unique
      end

      it "should report an empty unique scope" do
        expect(@login.unique_scope).to eq([])
      end
    end

    context "if unique multicolumn" do

      before(:each) do 
        create_table(User, :first => {}, :middle => {}, :last => { :index => {:with => [:first, :middle], :unique => true}})
        @first = User.columns.find{|column| column.name == "first"}
        @middle = User.columns.find{|column| column.name == "middle"}
        @last = User.columns.find{|column| column.name == "last"}
      end

      it "should report unique for each" do
        expect(@first).to be_unique
        expect(@middle).to be_unique
        expect(@last).to be_unique
      end

      it "should report unique scope for each" do
        expect(@first.unique_scope).to match_array(%W[middle last])
        expect(@middle.unique_scope).to match_array(%W[first last])
        expect(@last.unique_scope).to match_array(%W[first middle])
      end
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
