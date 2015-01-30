require 'spec_helper'
require 'stringio'

describe "Schema dump" do

  context 'with enum', :postgresql => :only do
    let(:connection) { ActiveRecord::Base.connection }

    it 'should include enum' do
      begin
        connection.execute "CREATE TYPE color AS ENUM ('red', 'green', 'blue')"
        expect(dump_schema).to match(%r{create_enum "color", "red", "green", "blue"})
      ensure
        connection.execute "DROP TYPE color"
      end
    end

    it 'should include enum with schema' do
      begin
        connection.execute "CREATE SCHEMA cmyk; CREATE TYPE cmyk.color AS ENUM ('cyan', 'magenta', 'yellow', 'black')"
        expect(dump_schema).to match(%r{create_enum "color", "cyan", "magenta", "yellow", "black", :schema => "cmyk"})
      ensure
        connection.execute "DROP SCHEMA cmyk CASCADE"
      end
    end
  end

  protected

  def dump_schema(opts={})
    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = Array.wrap(opts[:ignore]) || []
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end

end
