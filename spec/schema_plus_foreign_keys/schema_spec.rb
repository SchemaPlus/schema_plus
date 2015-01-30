require 'spec_helper'

describe ActiveRecord::Schema do

  let(:schema) { ActiveRecord::Schema }

  let(:connection) { ActiveRecord::Base.connection }

  context "defining with auto_index and auto_create" do

    around(:each) do |example|
      with_auto_index do
        with_auto_create do
          example.run
        end
      end
    end

    it "should pass" do
      expect { do_schema }.to_not raise_error
    end

    it "should create only explicity added indexes" do
      do_schema
      expected = SchemaDev::Rspec::Helpers.mysql? ? 2 : 1
      expect(connection.tables.collect { |table| connection.indexes(table) }.flatten.size).to eq(expected)
    end

    it "should create only explicity added foriegn keys" do
      do_schema
      expect(connection.tables.collect { |table| connection.foreign_keys(table) }.flatten.size).to eq(2)
    end

  protected

  def do_schema
    define_schema do

      create_table :users, :force => true do
      end

      create_table :colors, :force => true do
      end

      create_table :shoes, :force => true do
      end

      create_table :posts, :force => true do |t|
        t.integer :user_id, :references => :users, :index => true
        t.integer :shoe_id, :references => :shoes   # should not have an index (except mysql)
        t.integer :color_id   # should not have a foreign key nor index
      end
    end
  end

  end

  it "handles explicit foreign keys" do
    expect {
      with_auto_create(false) do
        define_schema do
          create_table :users, :force => :cascade do
          end

          create_table :posts, :force => :cascade do |t|
            t.integer :user_id
            t.foreign_key :users
          end
        end
      end
    }.not_to raise_error
    expect(connection.foreign_keys("posts").first.to_table).to eq "users"
  end


  protected


  def with_auto_index(value = true)
    old_value = SchemaPlusForeignKeys.config.auto_index
    SchemaPlusForeignKeys.config.auto_index = value
    begin
      yield
    ensure
      SchemaPlusForeignKeys.config.auto_index = old_value
    end
  end

  def with_auto_create(value = true)
    old_value = SchemaPlusForeignKeys.config.auto_create
    SchemaPlusForeignKeys.config.auto_create = value
    begin
      yield
    ensure
      SchemaPlusForeignKeys.config.auto_create = old_value
    end
  end

end
