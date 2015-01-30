require 'spec_helper'

describe ActiveRecord::Migration do

  before(:each) do
    define_schema(:auto_create => true) do
      create_table :posts, :force => true do |t|
        t.string :content
      end
    end
    class Post < ::ActiveRecord::Base ; end
  end

  context "when table is created" do

    before(:each) do
      @model = Post
    end

    it "should properly handle default values for booleans" do
      expect {
        recreate_table(@model) do |t|
          t.boolean :bool, :default => true
        end
      }.to_not raise_error
      expect(@model.create.reload.bool).to be true
    end

    it "should properly handle default values for json (#195)", :postgresql => :only do
      recreate_table(@model) do |t|
        t.json :json, :default => {}
      end
      expect(@model.create.reload.json).to eq({})
    end

  end

  def recreate_table(model, opts={}, &block)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table model.table_name, opts.merge(:force => true), &block
    end
    model.reset_column_information
  end
end
