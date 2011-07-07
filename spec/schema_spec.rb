require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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
      expect { define_schema }.should_not raise_error
    end

    it "should create only explicity added indexes" do
      define_schema
      connection.tables.collect { |table| connection.indexes(table) }.flatten.should have(1).item
    end

    it "should create only explicity added foriegn keys" do
      define_schema
      connection.tables.collect { |table| connection.foreign_keys(table) }.flatten.should have(1).item
    end

  end

  protected
  def define_schema
    ActiveRecord::Migration.suppress_messages do
      schema.define do
        connection.tables.each do |table| drop_table table end

        create_table :users, :force => true do
        end

        create_table :posts, :force => true do |t|
          t.integer :user_id, :references => :users, :index => true
        end
      end
    end
  end

  def with_auto_index(value = true)
    old_value = SchemaPlus.config.foreign_keys.auto_index
    SchemaPlus.config.foreign_keys.auto_index = value
    begin
      yield
    ensure
      SchemaPlus.config.foreign_keys.auto_index = old_value
    end
  end

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
