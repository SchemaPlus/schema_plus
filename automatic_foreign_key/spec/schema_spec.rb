require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ActiveRecord::Schema do

  let(:schema) { ActiveRecord::Schema }

  let(:connection) { ActiveRecord::Base.connection }

  context "defining with auto_index" do

    it "should pass" do

      with_auto_index do
        expect { define_schema }.should_not raise_error
      end

    end

    it "should create only explicity added indexes" do
      with_auto_index do
        define_schema
        connection.tables.collect { |table| connection.indexes(table) }.flatten.should have(1).item
      end
    end

  end

  protected
  def define_schema
    ActiveRecord::Migration.suppress_messages do
      schema.define do

        create_table :users, :force => true do
        end

        create_table :posts, :force => true do |t|
          t.integer :user_id
        end
        add_index :posts, :user_id
      end
    end
  end

  def with_auto_index(value = true)
    old_value = AutomaticForeignKey.auto_index
    AutomaticForeignKey.auto_index = value
    begin
      yield
    ensure
      AutomaticForeignKey.auto_index = old_value
    end
  end

end
