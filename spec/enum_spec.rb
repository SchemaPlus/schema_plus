require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def enum_fields(name, schema = 'public')
  sql = <<-SQL
    SELECT array_to_string(array_agg(E.enumlabel ORDER BY enumsortorder), ' ') AS "values"
    FROM pg_enum E
    JOIN pg_type T ON E.enumtypid = T.oid
    JOIN pg_namespace N ON N.oid = T.typnamespace
    WHERE N.nspname = '#{schema}' AND T.typname = '#{name}'
    GROUP BY T.oid;
  SQL

  data = ActiveRecord::Base.connection.select_all(sql)
  return nil if data.empty?
  data[0]['values'].split(' ')
end

describe 'enum', :postgresql => :only do
  before(:all) do ActiveRecord::Migration.verbose = false end

  let(:migration) { ActiveRecord::Migration }

  describe 'enums' do
    it 'should return all enums' do
      begin
        migration.execute 'create schema cmyk'
        migration.create_enum 'color', 'red', 'green', 'blue'
        migration.create_enum 'color', 'cyan', 'magenta', 'yellow', 'black', schema: 'cmyk'

        expect(migration.enums).to match_array [['cmyk', 'color', %w|cyan magenta yellow black|], ['public', 'color', %w|red green blue|]]
      ensure
        migration.drop_enum 'color'
        migration.execute 'drop schema cmyk cascade'
      end
    end
  end

  describe 'create_enum' do
    it 'should create enum with given values' do
      begin
        migration.create_enum 'color', *%w|red green blue|
        expect(enum_fields('color')).to eq(%w|red green blue|)
      ensure
        migration.execute 'DROP TYPE IF EXISTS color'
      end
    end

    it 'should create enum with schema' do
      begin
        migration.execute 'CREATE SCHEMA colors'
        migration.create_enum 'color', *%|red green blue|, schema: 'colors'
        expect(enum_fields('color', 'colors')).to eq(%w|red green blue|)
      ensure
        migration.execute 'DROP SCHEMA IF EXISTS colors CASCADE'
      end
    end

    it 'should escape enum value' do
      begin
        migration.create_enum('names', "O'Neal")
        expect(enum_fields('names')).to eq(["O'Neal"])
      ensure
        migration.execute "DROP TYPE IF EXISTS names"
      end
    end

    it 'should escape schame name and enum name' do
      begin
        migration.execute 'CREATE SCHEMA "select"'
        migration.create_enum 'where', *%|red green blue|, schema: 'select'
        expect(enum_fields('where', 'select')).to eq(%w|red green blue|)
      ensure
        migration.execute 'DROP SCHEMA IF EXISTS "select" CASCADE'
      end
    end

  end

  describe 'alter_enum' do
    before(:each) do migration.create_enum('color', 'red', 'green', 'blue') end
    after(:each) do migration.execute 'DROP TYPE IF EXISTS color' end

    it 'should add new value after all values' do
      migration.alter_enum('color', 'magenta')
      expect(enum_fields('color')).to eq(%w|red green blue magenta|)
    end

    it 'should add new value after existed' do
      migration.alter_enum('color', 'magenta', after: 'red')
      expect(enum_fields('color')).to eq(%w|red magenta green blue|)
    end

    it 'should add new value before existed' do
      migration.alter_enum('color', 'magenta', before: 'green')
      expect(enum_fields('color')).to eq(%w|red magenta green blue|)
    end

    it 'should add new value within given schema' do
      begin
        migration.execute 'CREATE SCHEMA colors'
        migration.create_enum('color', 'red', schema: 'colors')
        migration.alter_enum('color', 'green', schema: 'colors')

        expect(enum_fields('color', 'colors')).to eq(%w|red green|)
      ensure
        migration.execute 'DROP SCHEMA colors CASCADE'
      end
    end
  end

  describe 'drop_enum' do
    it 'should drop enum with given name' do
      migration.execute "CREATE TYPE color AS ENUM ('red', 'blue')"
      expect(enum_fields('color')).to eq(%w|red blue|)
      migration.drop_enum('color')

      expect(enum_fields('color')).to be_nil
    end

    it 'should drop enum within given name and schema' do
      begin
        migration.execute "CREATE SCHEMA colors; CREATE TYPE colors.color AS ENUM ('red', 'blue')"
        expect(enum_fields('color', 'colors')).to eq(%w|red blue|)
        migration.drop_enum('color', schema: 'colors')

        expect(enum_fields('color', 'colors')).to be_nil
      ensure
        migration.execute "DROP SCHEMA colors CASCADE"
      end
    end
  end
end
