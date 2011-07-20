require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe "Index definition" do

  let(:migration) { ::ActiveRecord::Migration }
  
  before(:all) do
    load_core_schema
  end

  around(:each) do |example|
    migration.suppress_messages do
      example.run
    end
  end

  after(:each) do
    migration.remove_index :users, :name => 'users_login_index' if migration.index_name_exists? :users, 'users_login_index', true
  end

  context "when index is multicolumn" do
    before(:each) do
      migration.execute "CREATE INDEX users_login_index ON users (login, deleted_at)"
      User.reset_column_information
      @index = index_definition(%w[login deleted_at])
    end

    it "is included in User.indexes" do
      User.indexes.select { |index| index.columns == %w[login deleted_at] }.should have(1).item
    end

  end

  it "should correctly report supports_partial_indexes?" do
    query = lambda { migration.execute "CREATE INDEX users_login_index ON users(login) WHERE deleted_at IS NULL" }
    if migration.supports_partial_indexes?
      query.should_not raise_error
    else
      query.should raise_error
    end
  end

  if SchemaPlusHelpers.postgresql?

    context "when case insensitive is added" do

      before(:each) do
        migration.execute "CREATE INDEX users_login_index ON users(LOWER(login))"
        User.reset_column_information
        @index = User.indexes.detect { |i| i.expression =~ /lower\(\(login\)::text\)/i }
      end

      it "is included in User.indexes" do
        @index.should_not be_nil
      end

      it "is not case_sensitive" do
        @index.should_not be_case_sensitive
      end

      it "its column should not be case sensitive" do
        User.columns.find{|column| column.name == "login"}.should_not be_case_sensitive
      end

      it "defines expression" do
        @index.expression.should == "lower((login)::text)"
      end

      it "doesn't define conditions" do
        @index.conditions.should be_nil
      end

    end


    context "when index is partial and column is not downcased" do
      before(:each) do
        migration.execute "CREATE INDEX users_login_index ON users(login) WHERE deleted_at IS NULL"
        User.reset_column_information
        @index = index_definition("login")
      end

      it "is included in User.indexes" do
        User.indexes.select { |index| index.columns == ["login"] }.should have(1).item
      end

      it "is case_sensitive" do
        @index.should be_case_sensitive
      end

      it "doesn't define expression" do
        @index.expression.should be_nil
      end

      it "defines conditions" do
        @index.conditions.should == "(deleted_at IS NULL)"
      end

    end

    context "when index contains expression" do
      before(:each) do
        migration.execute "CREATE INDEX users_login_index ON users (extract(EPOCH from deleted_at)) WHERE deleted_at IS NULL"
        User.reset_column_information
        @index = User.indexes.detect { |i| i.expression.present? }
      end

      it "exists" do
        @index.should_not be_nil
      end

      it "doesnt have columns defined" do
        @index.columns.should be_empty
      end

      it "is case_sensitive" do
        @index.should be_case_sensitive
      end

      it "defines expression" do
        @index.expression.should == "date_part('epoch'::text, deleted_at)"
      end

      it "defines conditions" do
        @index.conditions.should == "(deleted_at IS NULL)"
      end

    end

  end # of postgresql specific examples

  protected
  def index_definition(column_names)
    User.indexes.detect { |index| index.columns == Array(column_names) }
  end


end
