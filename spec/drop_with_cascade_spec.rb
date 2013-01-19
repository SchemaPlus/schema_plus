require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Drop with Cascade" do

  let(:migration) { ::ActiveRecord::Migration }

  if SchemaPlusHelpers.postgresql?

    context "cascade option" do
      before do
        define_schema(:auto_create => true) do
          create_table :parents, :force => true do |t|
            t.string :name
          end
          execute "CREATE TABLE a_through_l_children ( CHECK ( name < 'm' ) ) INHERITS (parents)"
          execute "CREATE TABLE m_through_z_children ( CHECK ( name >= 'm' ) ) INHERITS (parents)"
        end
        class Parent < ::ActiveRecord::Base ; end
        Parent.connection.table_exists?('parents').should be_true
        Parent.connection.table_exists?('a_through_l_children').should be_true
        Parent.connection.table_exists?('m_through_z_children').should be_true
      end

      context 'drop_table' do

        it "should successfully drop the inherited table and all the inheriting tables" do
          Parent.connection.drop_table('parents', :cascade => true)
          Parent.connection.table_exists?('parents').should be_false
          Parent.connection.table_exists?('a_through_l_children').should be_false
          Parent.connection.table_exists?('m_through_z_children').should be_false
        end
      end

      context 'create_table' do

        it "should successfully pass the cascade option on to drop_table" do
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Schema.define do
              create_table :parents, :force => true, :cascade => true do |t|
                t.string :name
              end
            end
          end
          Parent.connection.table_exists?('parents').should be_true
          Parent.connection.table_exists?('a_through_l_children').should be_false
          Parent.connection.table_exists?('m_through_z_children').should be_false
        end
      end

    end

  end
end
