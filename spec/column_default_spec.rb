require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe "Column definition" do
  before(:each) do
    define_schema(:auto_create => true) do
      create_table :models, :force => true do |t|
      end
    end
    class Model < ::ActiveRecord::Base ; end
  end

  subject {
    Model.connection.execute("INSERT INTO models (dummy) values (1)")
    Model.last.reload.test_column
  }

  context "text columns" do

    before(:each) do
      @nowish = /(#{Time.now.utc.to_s.sub(/:[^:]+$/, '')}|#{Time.now.to_s.sub(/:[^:]+$/,'')}).*/
    end

    context "just default passed" do
      before(:each) do
        define_test_column(:string, :default => "2011-12-11 00:00:00")
      end

      it "should use the normal default" do
        is_expected.to eq "2011-12-11 00:00:00"
      end
    end

    context "just default passed in hash" do
      before(:each) do
        define_test_column(:string, :default => { :value => "2011-12-11 00:00:00" })
      end

      it "should use the normal default" do
        is_expected.to eq "2011-12-11 00:00:00"
      end
    end

    context "default passed with no nulls" do
      before(:each) do
        define_test_column(:string, :default => "2011-12-11 00:00:00", null: false)
      end

      it "should use the normal default" do
        is_expected.to eq "2011-12-11 00:00:00"
      end
    end

    context "default passed in hash with no nulls" do
      before(:each) do
        define_test_column(:string, :default => { :value => "2011-12-11 00:00:00" }, null: false)
      end

      it "should use the normal default" do
        is_expected.to eq "2011-12-11 00:00:00"
      end
    end

    context "default function passed as :now" do
      before(:each) do
        begin
          define_test_column(:string, :default => :now)
        rescue ArgumentError => e
          @raised_argument_error = e
        end
      end

      if SchemaPlusHelpers.mysql?
        it "should raise an error" do
          expect(@raised_argument_error).to be_a ArgumentError
        end
      else
        it "should use NOW() as the default" do
          is_expected.to match @nowish
        end
      end
    end

    context "default function passed as now with no nulls" do
      before(:each) do
        begin
          define_test_column(:string, :default => :now, null: false)
        rescue ArgumentError => e
          @raised_argument_error = e
        end
      end

      if SchemaPlusHelpers.mysql?
        it "should raise an error" do
          expect(@raised_argument_error).to be_a ArgumentError
        end
      else
        it "should use NOW() as the default" do
          is_expected.to match @nowish
        end
      end
    end

    context "valid expr passed as default" do
      if SchemaPlusHelpers.mysql?
        it "raises an error" do
          expect {
            define_test_column(:string, :default => { :expr => "(replace('THIS IS A TEST', 'TEST', 'DOG'))" })
          }.to raise_error ArgumentError
        end
      else
        it "uses the expression" do
          define_test_column(:string, :default => { :expr => "(replace('THIS IS A TEST', 'TEST', 'DOG'))" })
          is_expected.to eq "THIS IS A DOG"
        end
      end
    end

  end

  context "boolean column" do

    context "passed as boolean false" do
      before(:each) do
        define_test_column :boolean, :default => false
      end

      it "should give the default as false" do
        is_expected.to eq false
      end
    end

    context "passed as boolean true" do
      before(:each) do
        define_test_column :boolean, :default => true
      end

      it "should give the default as true" do
        is_expected.to eq true
      end
    end
  end

  private 

  def define_test_column(type, *args)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table Model.table_name, :force => true do |t|
        t.send type, :test_column, *args
        t.integer :dummy
      end
    end
    Model.reset_column_information
    @column = Model.columns.first()
  end
end
