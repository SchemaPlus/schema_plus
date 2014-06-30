require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe "Column definition" do
  before(:all) do
    define_schema(:auto_create => false) do
      create_table :users, :force => true do |t|
        t.string :login
        t.datetime :deleted_at
      end

      create_table :posts, :force => true do |t|
        t.text :body
        t.integer :user_id
        t.integer :author_id
      end

      create_table :comments, :force => true do |t|
        t.text :body
        t.integer :post_id
        t.foreign_key :post_id, :posts, :id
      end
    end
  end

  def call_add_column_options!(*params, &block)
    if ::ActiveRecord::VERSION::MAJOR >= 4
      ActiveRecord::Base.connection.schema_creation.send(:add_column_options!, *params, &block)
    else
      ActiveRecord::Base.connection.add_column_options!(*params, &block)
    end
  end

  context "text columns" do
    before(:each) do
      @sql = 'time_taken text'
    end

    context "just default passed" do
      before(:each) do
        call_add_column_options!(@sql, { :default => "2011-12-11 00:00:00" })
      end

      subject { @sql}

      it "should use the normal default" do
        is_expected.to eq("time_taken text DEFAULT '2011-12-11 00:00:00'")
      end
    end

    context "just default passed in hash" do
      before(:each) do
        call_add_column_options!(@sql, { :default => { :value => "2011-12-11 00:00:00" } })
      end

      subject { @sql}

      it "should use the normal default" do
        is_expected.to eq("time_taken text DEFAULT '2011-12-11 00:00:00'")
      end
    end

    context "default passed with no nulls" do
      before(:each) do
        call_add_column_options!(@sql, { :default => "2011-12-11 00:00:00", null: false })
      end

      subject { @sql}

      it "should use the normal default" do
        is_expected.to eq("time_taken text DEFAULT '2011-12-11 00:00:00' NOT NULL")
      end
    end

    context "default passed in hash with no nulls" do
      before(:each) do
        call_add_column_options!(@sql, { :default => { :value => "2011-12-11 00:00:00" }, null: false })
      end

      subject { @sql}

      it "should use the normal default" do
        is_expected.to eq("time_taken text DEFAULT '2011-12-11 00:00:00' NOT NULL")
      end
    end

    context "default function passed as now" do
      before(:each) do
        begin
          call_add_column_options!(@sql, { :default => :now })
        rescue ArgumentError => e
          @raised_argument_error = e
        end
      end

      subject { @sql }

      if SchemaPlusHelpers.postgresql?
        it "should use NOW() as the default" do
          is_expected.to eq("time_taken text DEFAULT NOW()")
        end
      end

      if SchemaPlusHelpers.sqlite3?
        it "should use NOW() as the default" do
          is_expected.to eq("time_taken text DEFAULT (DATETIME('now'))")
        end
      end

      if SchemaPlusHelpers.mysql?
        it "should raise an error" do
          expect(@raised_argument_error).to be_a ArgumentError
        end
      end
    end

    context "default function passed as now with no nulls" do
      before(:each) do
        begin
          call_add_column_options!(@sql, { :default => :now, null: false })
        rescue ArgumentError => e
          @raised_argument_error = e
        end
      end

      subject { @sql }

      if SchemaPlusHelpers.postgresql?
        it "should use NOW() as the default" do
          is_expected.to eq("time_taken text DEFAULT NOW() NOT NULL")
        end
      end

      if SchemaPlusHelpers.sqlite3?
        it "should use NOW() as the default" do
          is_expected.to eq("time_taken text DEFAULT (DATETIME('now')) NOT NULL")
        end
      end

      if SchemaPlusHelpers.mysql?
        it "should raise an error" do
          expect(@raised_argument_error).to be_a ArgumentError
        end
      end
    end

    context "valid expr passed as default" do
      subject { call_add_column_options!(@sql, { :default => { :expr => 'NOW()' } }); @sql }

      if SchemaPlusHelpers.postgresql?
        it "should use NOW() as the default" do
          is_expected.to eq("time_taken text DEFAULT NOW()")
        end
      end

      if SchemaPlusHelpers.sqlite3?
        it "should use NOW() as the default" do
          is_expected.to eq("time_taken text DEFAULT NOW()")
        end
      end

      if SchemaPlusHelpers.mysql?
        it "should raise an error" do
          expect { subject }.to raise_error
        end
      end
    end

    context "invalid expr passed as default" do
      if SchemaPlusHelpers.mysql?
        it "should raise an error" do
          expect {call_add_column_options!(@sql, { :default => { :expr => "ARBITRARY_EXPR" } })}.to raise_error ArgumentError
        end
      else
        it "should just accept the SQL" do
          call_add_column_options!(@sql, { :default => { :expr => "ARBITRARY_EXPR" } })
          expect(@sql).to eq("time_taken text DEFAULT ARBITRARY_EXPR")
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
        call_add_column_options!(@sql, { :default => false })
      end

      subject { @sql}

      it "should give the default as false" do
        is_expected.to match(/boolean DEFAULT (\'f\'|0)/)
      end
    end

    context "passed as boolean true" do
      before(:each) do
        call_add_column_options!(@sql, { :default => true })
      end

      subject { @sql}

      it "should give the default as true" do
        is_expected.to match(/boolean DEFAULT (\'t\'|1)/)
      end
    end
  end
end
