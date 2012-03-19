require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe "Column definition" do
  before(:all) do
    load_core_schema
  end

  let(:connection) { ActiveRecord::Base.connection }

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
      connection.add_column_options!(@sql, { :default => :now })
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
      it "should use CURRENT_TIMESTAMP as the default" do
        should == "time_taken text DEFAULT 'now'"
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
