require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Item < ActiveRecord::Base
end

class AOnes < ActiveRecord::Base
end

class ABOnes < ActiveRecord::Base
end

describe ActiveRecord do

  let(:schema) { ActiveRecord::Schema }

  let(:migration) { ActiveRecord::Migration }

  let(:connection) { ActiveRecord::Base.connection }

  context "views" do

    around (:each) do |example|
      define_schema_and_data
      example.run
      drop_definitions
    end

    it "should query correctly" do
      expect(AOnes.all.collect(&:s)).to eq(%W[one_one one_two])
      expect(ABOnes.all.collect(&:s)).to eq(%W[one_one])
    end

    it "should instrospect" do
      # for postgresql, ignore views named pg_*
      expect(connection.views.sort).to eq(%W[a_ones ab_ones])
      expect(connection.view_definition('a_ones')).to match(%r{^ ?SELECT .*b.*,.*s.* FROM .*items.* WHERE .*a.* = 1}mi)
      expect(connection.view_definition('ab_ones')).to match(%r{^ ?SELECT .*s.* FROM .*a_ones.* WHERE .*b.* = 1}mi)
    end

    it "should not be listed as a table" do
      expect(connection.tables).not_to include('a_ones')
      expect(connection.tables).not_to include('ab_ones')
    end


    it "should be included in schema dump" do
      expect(dump).to match(%r{create_view "a_ones", " ?SELECT .*b.*,.*s.* FROM .*items.* WHERE .*a.* = 1.*, :force => true}mi)
      expect(dump).to match(%r{create_view "ab_ones", " ?SELECT .*s.* FROM .*a_ones.* WHERE .*b.* = 1.*, :force => true}mi)
    end

    it "should be included in schema dump in dependency order" do
      expect(dump).to match(%r{create_table "items".*create_view "a_ones".*create_view "ab_ones"}m) 
    end

    it "should not be included in schema if listed in ignore_tables" do
      dump(ignore_tables: /b_/) do |dump|
        expect(dump).to match(%r{create_view "a_ones", " ?SELECT .*b.*,.*s.* FROM .*items.* WHERE .*a.* = 1.*, :force => true}mi)
        expect(dump).not_to match(%r{"ab_ones"})
      end
    end


    it "dump should not reference current database" do
      # why check this?  mysql default to providing the view definition
      # with tables explicitly scoped to the current database, which
      # resulted in the dump being bound to the current database.  this
      # caused trouble for rails, in which creates the schema dump file
      # when in the (say) development database, but then uses it to
      # initialize the test database when testing.  this meant that the
      # test database had views into the development database.
      db = connection.respond_to?(:current_database)? connection.current_database : ActiveRecord::Base.configurations['schema_plus'][:database]
      expect(dump).not_to match(%r{#{connection.quote_table_name(db)}[.]})
    end

    context "duplicate view creation" do
      around(:each) do |example|
        migration.suppress_messages do
          begin
            migration.create_view('dupe_me', 'SELECT * FROM items WHERE (a=1)')
            example.run
          ensure
            migration.drop_view('dupe_me')
          end
        end
      end


      it "should raise an error by default" do
        expect {migration.create_view('dupe_me', 'SELECT * FROM items WHERE (a=2)')}.to raise_error ActiveRecord::StatementInvalid
      end

      it "should override existing definition if :force true" do
        migration.create_view('dupe_me', 'SELECT * FROM items WHERE (a=2)', :force => true)
        expect(connection.view_definition('dupe_me')).to match(%r{WHERE .*a.*=.*2}i)
      end
    end

    if SchemaPlusHelpers.mysql?
      context "in mysql" do

        around(:each) do |example|
          migration.suppress_messages do
            begin
              migration.drop_view :check if connection.views.include? 'check'
              example.run
            ensure
              migration.drop_view :check if connection.views.include? 'check'
            end
          end
        end

        it "should introspect WITH CHECK OPTION" do
          migration.create_view :check, 'SELECT * FROM items WHERE (a=2) WITH CHECK OPTION'
          expect(connection.view_definition('check')).to match(%r{WITH CASCADED CHECK OPTION$})
        end

        it "should introspect WITH CASCADED CHECK OPTION" do
          migration.create_view :check, 'SELECT * FROM items WHERE (a=2) WITH CASCADED CHECK OPTION'
          expect(connection.view_definition('check')).to match(%r{WITH CASCADED CHECK OPTION$})
        end

        it "should introspect WITH LOCAL CHECK OPTION" do
          migration.create_view :check, 'SELECT * FROM items WHERE (a=2) WITH LOCAL CHECK OPTION'
          expect(connection.view_definition('check')).to match(%r{WITH LOCAL CHECK OPTION$})
        end
      end 
    end
  end

  protected

  def define_schema_and_data
    migration.suppress_messages do
      connection.views.each do |view| connection.drop_view view end
      connection.tables.each do |table| connection.drop_table table, cascade: true end

      schema.define do

        create_table :items, :force => true do |t|
          t.integer :a
          t.integer :b
          t.string  :s
        end

        create_view :a_ones, Item.select('b, s').where(:a => 1)
        create_view :ab_ones, "select s from a_ones where b = 1"
        create_view :pg_dummy_internal, "select 1" if SchemaPlusHelpers.postgresql?
      end
    end
    connection.execute "insert into items (a, b, s) values (1, 1, 'one_one')"
    connection.execute "insert into items (a, b, s) values (1, 2, 'one_two')"
    connection.execute "insert into items (a, b, s) values (2, 1, 'two_one')"
    connection.execute "insert into items (a, b, s) values (2, 2, 'two_two')"

  end

  def drop_definitions
    migration.suppress_messages do
      schema.define do
        drop_view "ab_ones"
        drop_view "a_ones"
        drop_table "items"
        drop_view :pg_dummy_internal if SchemaPlusHelpers.postgresql?
      end
    end
  end

  def dump(opts={})
    StringIO.open { |stream|
      ActiveRecord::SchemaDumper.ignore_tables = Array.wrap(opts[:ignore_tables])
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
      yield stream.string if block_given?
      stream.string
    }
  end

end
