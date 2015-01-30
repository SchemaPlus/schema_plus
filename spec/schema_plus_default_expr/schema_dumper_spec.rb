require 'spec_helper'
require 'stringio'

describe "Schema dump" do

  before(:all) do
    SchemaPlusForeignKeys.setup do |config|
      config.auto_create = false
    end
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        connection.tables.each do |table| drop_table table, :cascade => true end

        create_table :posts, :force => true do |t|
          t.text :body
          t.integer :user_id
          t.integer :first_comment_id
          t.string :string_no_default
          t.integer :short_id
          t.string :str_short
          t.integer :integer_col
          t.float :float_col
          t.decimal :decimal_col
          t.datetime :datetime_col
          t.timestamp :timestamp_col
          t.time :time_col
          t.date :date_col
          t.binary :binary_col
          t.boolean :boolean_col
        end

      end
    end
    class ::Post < ActiveRecord::Base ; end
  end

  context "with date default", :postgresql => :only do
    it "should dump the default hash expr as now()" do
      with_additional_column Post, :posted_at, :datetime, :default => :now do
        expect(dump_posts).to match(%r{t\.datetime\s+"posted_at",\s*(?:default:|:default =>)\s*\{\s*(?:expr:|:expr\s*=>)\s*"now\(\)"\s*\}})
      end
    end

    it "should dump the default hash expr as CURRENT_TIMESTAMP" do
      with_additional_column Post, :posted_at, :datetime, :default => {:expr => 'date \'2001-09-28\''} do
        expect(dump_posts).to match(%r{t\.datetime\s+"posted_at",\s*(?:default:|:default =>).*2001-09-28.*})
      end
    end

    it "can dump a complex default expression" do
      with_additional_column Post, :name, :string, :default => {:expr => 'substring(random()::text from 3 for 6)'} do
        expect(dump_posts).to match(%r{t\.string\s+"name",\s*(?:default:|:default\s*=>)\s*{\s*(?:expr:|:expr\s*=>)\s*"\\"substring\\"\(\(random\(\)\)::text, 3, 6\)"\s*}})
      end
    end
  end

  context "with date default", :sqlite3 => :only do
    it "should dump the default hash expr as now" do
      with_additional_column Post, :posted_at, :datetime, :default => :now do
        expect(dump_posts).to match(%r{t\.datetime\s+"posted_at",\s*(?:default:|:default =>)\s*\{\s*(?:expr:|:expr =>)\s*"\(DATETIME\('now'\)\)"\s*\}})
      end
    end

    it "should dump the default hash expr string as now" do
      with_additional_column Post, :posted_at, :datetime, :default => { :expr => "(DATETIME('now'))" } do
        expect(dump_posts).to match(%r{t\.datetime\s+"posted_at",\s*(?:default:|:default =>)\s*\{\s*(?:expr:|:expr =>)\s*"\(DATETIME\('now'\)\)"\s*\}})
      end
    end

    it "should dump the default value normally" do
      with_additional_column Post, :posted_at, :string, :default => "now" do
        expect(dump_posts).to match(%r{t\.string\s*"posted_at",\s*(?:default:|:default =>)\s*"now"})
      end
    end
  end

  it "should leave out :default when default was changed to null" do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.change_column_default :posts, :string_no_default, nil
    end
    # mysql2 includes 'limit: 255' in the output.  that's OK, just want to
    # make sure the full line doesn't have 'default' in it.
    expect(dump_posts).to match(%r{t\.string\s+"string_no_default"\s*(,\s*limit:\s*\d+)?$})
  end

  protected
  def to_regexp(string)
    Regexp.new(Regexp.escape(string))
  end

  def with_additional_column(model, column_name, column_type, options)
    table_columns = model.columns.reject{|column| column.name == 'id'}
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table model.table_name, :force => true do |t|
        table_columns.each do |column|
          t.column column.name, column.type, :default => column.default
        end
        t.column column_name, column_type, options
      end
    end
    yield
  end

  def dump_schema(opts={})
    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = Array.wrap(opts[:ignore]) || []
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end

  def dump_posts
    dump_schema(:ignore => %w[users comments])
  end

end

