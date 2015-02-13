require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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
             when "#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}".to_r <= "4.1".to_r
               { "type" => "string" }
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

  context "using DB_DEFAULT" do

    before(:each) do
      create_table(User, :alpha => { :default => "gabba" }, :beta => {})
    end

    it "creating a record should respect default expression", :sqlite3 => :skip do
      User.create!(:alpha => ActiveRecord::DB_DEFAULT, :beta => "hello")
      expect(User.last.alpha).to eq("gabba")
      expect(User.last.beta).to eq("hello")
    end

    it "creating a record should raise an error", :sqlite3 => :only do
      expect { User.create!(:alpha => ActiveRecord::DB_DEFAULT, :beta => "hello") }.to raise_error ActiveRecord::StatementInvalid
    end

    it "updating a record should respect default expression", :sqlite3 => :skip do
      u = User.create!(:alpha => "hey", :beta => "hello")
      u.reload
      expect(u.alpha).to eq("hey")
      expect(u.beta).to eq("hello")
      u.update_attributes(:alpha => ActiveRecord::DB_DEFAULT, :beta => "goodbye")
      u.reload
      expect(u.alpha).to eq("gabba")
      expect(u.beta).to eq("goodbye")
    end

    it "updating a record should raise an error", :sqlite3 => :only do
      u = User.create!(:alpha => "hey", :beta => "hello")
      expect { u.update_attributes(:alpha => ActiveRecord::DB_DEFAULT, :beta => "goodbye") }.to raise_error ActiveRecord::StatementInvalid
    end
  end

  context "Postgresql array", :postgresql => :only do

    before(:each) do
      create_table(User, :alpha => { :default => [], :array => true })
    end

    it "respects array: true" do
      column = User.columns.find(&its.name == "alpha")
      expect(column.array).to be_truthy
    end
  end if "#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}".to_r >= "4.0".to_r

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
