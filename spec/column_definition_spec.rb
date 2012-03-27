require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe "Column definition" do
  before(:all) do
    load_core_schema
  end

  let(:connection) { ActiveRecord::Base.connection }

  context "text columns" do
    before(:each) do
      @sql = 'time_taken text'
    end

    context "just default passed" do
      before(:each) do
        connection.add_column_options!(@sql, { :default => "2011-12-11 00:00:00" })
      end

      subject { @sql}

      it "should use the normal default" do
        should == "time_taken text DEFAULT '2011-12-11 00:00:00'"
      end
    end

    context "just default passed in hash" do
      before(:each) do
        connection.add_column_options!(@sql, { :default => { :value => "2011-12-11 00:00:00" } })
      end

      subject { @sql}

      it "should use the normal default" do
        should == "time_taken text DEFAULT '2011-12-11 00:00:00'"
      end
    end

    context "default function passed as now" do
      before(:each) do
        begin
          connection.add_column_options!(@sql, { :default => :now })
        rescue ArgumentError => e
          @raised_argument_error = e
        end
      end

      subject { @sql }

      if SchemaPlusHelpers.postgresql?
        it "should use NOW() as the default" do
          should == "time_taken text DEFAULT NOW()"
        end
      end

      if SchemaPlusHelpers.sqlite3?
        it "should use NOW() as the default" do
          should == "time_taken text DEFAULT (DATETIME('now'))"
        end
      end

      if SchemaPlusHelpers.mysql?
        it "should raise an error" do
          @raised_argument_error.should be_a ArgumentError
        end
      end
    end

    context "valid expr passed as default" do
      subject { connection.add_column_options!(@sql, { :default => { :expr => 'NOW()' } }); @sql }

      if SchemaPlusHelpers.postgresql?
        it "should use NOW() as the default" do
          should == "time_taken text DEFAULT NOW()"
        end
      end

      if SchemaPlusHelpers.sqlite3?
        it "should use NOW() as the default" do
          should == "time_taken text DEFAULT NOW()"
        end
      end

      if SchemaPlusHelpers.mysql?
        it "should raise an error" do
          lambda { subject }.should raise_error
        end
      end
    end

    context "invalid expr passed as default" do
      if SchemaPlusHelpers.mysql?
        it "should raise an error" do
          lambda {connection.add_column_options!(@sql, { :default => { :expr => "ARBITRARY_EXPR" } })}.should raise_error ArgumentError
        end
      else
        it "should just accept the SQL" do
          connection.add_column_options!(@sql, { :default => { :expr => "ARBITRARY_EXPR" } })
          @sql.should == "time_taken text DEFAULT ARBITRARY_EXPR"
        end
      end
    end
  end

  context "boolean column" do
    before(:each) do
      @sql = 'time_taken boolean'
    end

    context "passed as boolean false" do
      before(:each) do
        connection.add_column_options!(@sql, { :default => false })
      end

      subject { @sql}

      it "should give the default as false" do
        should match /boolean DEFAULT (\'f\'|0)/
      end
    end

    context "passed as boolean true" do
      before(:each) do
        connection.add_column_options!(@sql, { :default => true })
      end

      subject { @sql}

      it "should give the default as true" do
        should match /boolean DEFAULT (\'t\'|1)/
      end
    end
  end
end
