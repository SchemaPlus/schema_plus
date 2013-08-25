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
      JSON.parse(@login.to_json).should include("name" => "login", "type" => "string")
    end
  end

  context "regarding indexes" do

    context "if not unique" do

      before (:each) do 
        create_table(User, :login => { :index => true})
        @login = User.columns.find{|column| column.name == "login"}
      end

      it "should report not unique" do
        @login.should_not be_unique
      end

      it "should report nil unique scope" do
        create_table(User, :login => { :index => true})
        @login.unique_scope.should be_nil
      end
    end

    context "if unique single column" do
      before (:each) do 
        create_table(User, :login => { :index => :unique})
        @login = User.columns.find{|column| column.name == "login"}
      end

      it "should report unique" do
        @login.should be_unique
      end

      it "should report an empty unique scope" do
        @login.unique_scope.should == []
      end
    end

    context "if unique multicolumn" do

      before (:each) do 
        create_table(User, :first => {}, :middle => {}, :last => { :index => {:with => [:first, :middle], :unique => true}})
        @first = User.columns.find{|column| column.name == "first"}
        @middle = User.columns.find{|column| column.name == "middle"}
        @last = User.columns.find{|column| column.name == "last"}
      end

      it "should report unique for each" do
        @first.should be_unique
        @middle.should be_unique
        @last.should be_unique
      end

      it "should report unique scope for each" do
        @first.unique_scope.should =~ %W[middle last]
        @middle.unique_scope.should =~ %W[first last]
        @last.unique_scope.should =~ %W[first middle]
      end
    end

  end

  context "regarding when it requires a value" do

    it "not required if the column can be null" do
      create_table(User, :login => { :null => true})
      User.columns.find{|column| column.name == "login"}.required_on.should be_nil
    end

    it "must have a value on :save if there's no default" do
      create_table(User, :login => { :null => false })
      User.columns.find{|column| column.name == "login"}.required_on.should == :save
    end

    it "must have a value on :update if there's default" do
      create_table(User, :login => { :null => false, :default => "foo" })
      User.columns.find{|column| column.name == "login"}.required_on.should == :update
    end

  end

  context "using DB_DEFAULT with non-expression default" do

    before(:each) do
      create_table(User, :alpha => { :default => "gabba" }, :beta => {})
    end

    it "creating a model should have default values" do
      User.new.alpha.should == "gabba"
      User.new.beta.should be_nil
    end

    it "creating a record should respect default expression when leaving value unspecified" do
      User.create!(:beta => "hello")
      User.last.alpha.should == "gabba"
      User.last.beta.should == "hello"
    end

    it "creating a record should respect specified nil" do
      User.create!(:alpha => nil, :beta => "hello")
      User.last.alpha.should be_nil
      User.last.beta.should == "hello"
    end

    if SchemaPlusHelpers.sqlite3?

      it "creating a record should raise an error" do
        expect { User.create!(:alpha => ActiveRecord::DB_DEFAULT, :beta => "hello") }.to raise_error ActiveRecord::StatementInvalid
      end
      it "updating a record should raise an error" do
        u = User.create!(:alpha => "hey", :beta => "hello")
        expect { u.update_attributes(:alpha => ActiveRecord::DB_DEFAULT, :beta => "goodbye") }.to raise_error ActiveRecord::StatementInvalid
      end

    else

      it "creating a record should respect default expression when using DB_DEFAULT" do
        User.create!(:alpha => ActiveRecord::DB_DEFAULT, :beta => "hello")
        User.last.alpha.should == "gabba"
        User.last.beta.should == "hello"
      end

      it "updating a record should respect default expression" do
        u = User.create!(:alpha => "hey", :beta => "hello")
        u.reload
        u.alpha.should == "hey"
        u.beta.should == "hello"
        u.update_attributes(:alpha => ActiveRecord::DB_DEFAULT, :beta => "goodbye")
        u.reload
        u.alpha.should == "gabba"
        u.beta.should == "goodbye"
      end

    end
  end

  context "using expression default" do

    case
    when SchemaPlusHelpers.mysql?

      it "create_table should fail" do
        expect do
          create_table(User, :login => { :null => false, :default => :now })
        end.to raise_error(ArgumentError, /Invalid default expression/)
      end

    when SchemaPlusHelpers.postgresql?

      before(:each) do
        create_table(User, :alpha => { :type => :datetime, :default => :now }, :beta => {})
      end

      it "creating a model should have DB_DEFAULT values" do
        User.new.alpha.should == ActiveRecord::DB_DEFAULT
        User.new.beta.should be_nil
      end

      it "creating a record should respect default expression when leaving value unspecified" do
        User.create!(:beta => "hello")
        User.last.alpha.should_not be_nil
        User.last.beta.should == "hello"
      end

      it "creating a record should respect default expression when using DB_DEFAULT" do
        User.create!(:alpha => ActiveRecord::DB_DEFAULT, :beta => "hello")
        User.last.alpha.should_not be_nil
        User.last.beta.should == "hello"
      end

      it "creating a record should respect specified nil" do
        User.create!(:alpha => nil, :beta => "hello")
        User.last.alpha.should be_nil
        User.last.beta.should == "hello"
      end

      it "updating a record should respect default expression" do
        u = User.create!(:alpha => Time.gm(1996, 12, 25), :beta => "hello")
        u.reload
        u.alpha.should == Time.gm(1996, 12, 25)
        u.beta.should == "hello"
        u.update_attributes(:alpha => ActiveRecord::DB_DEFAULT, :beta => "goodbye")
        u.reload
        u.alpha.should_not == Time.gm(1996, 12, 25)
        u.beta.should == "goodbye"
      end

    when SchemaPlusHelpers.sqlite3?

      before(:each) do
        create_table(User, :alpha => { :type => :datetime, :default => :now }, :beta => {})
      end

      if ::ActiveRecord::VERSION::MAJOR >= 4

        it "creating a record should respect default expression when leaving value unspecified" do
          User.create!(:beta => "hello")
          User.last.alpha.should_not be_nil
          User.last.beta.should == "hello"
        end

        it "creating a record fails to respect specified nil" do
          User.create!(:alpha => nil, :beta => "hello")
          User.last.alpha.should_not be_nil
          User.last.beta.should == "hello"
        end

      else

        it "creating a record fails to respect default expression when leaving value unspecified" do
          User.create!(:beta => "hello")
          User.last.alpha.should be_nil
          User.last.beta.should == "hello"
        end

        it "creating a record should respect specified nil" do
          User.create!(:alpha => nil, :beta => "hello")
          User.last.alpha.should be_nil
          User.last.beta.should == "hello"
        end

      end

    end
  end

  protected

  def create_table(model, columns_with_options)
    migration.suppress_messages do
      migration.create_table model.table_name, :force => true do |t|
        columns_with_options.each_pair do |column, options|
          t.send options.fetch(:type, :string), column, options.except(:type)
        end
      end
      model.reset_column_information
    end
  end

end
