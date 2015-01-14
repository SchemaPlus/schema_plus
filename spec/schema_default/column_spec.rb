describe SchemaDefault do

  let(:migration) { ::ActiveRecord::Migration }

  before(:each) do
    create_table(User, :alpha => { :default => "gabba" }, :beta => {})
    class User < ::ActiveRecord::Base ; end
  end

  context "uses db default value", :sqlite3 => :skip do

    it "when creating a record with DB_DEFAULT" do
      User.create!(:alpha => ActiveRecord::DB_DEFAULT, :beta => "hello")
      expect(User.last.alpha).to eq("gabba")
      expect(User.last.beta).to eq("hello")
    end

    it "when updating a record with DB_DEFAULT" do
      u = User.create!(:alpha => "hey", :beta => "hello")
      u.reload
      expect(u.alpha).to eq("hey")
      expect(u.beta).to eq("hello")
      u.update_attributes(:alpha => ActiveRecord::DB_DEFAULT, :beta => "goodbye")
      u.reload
      expect(u.alpha).to eq("gabba")
      expect(u.beta).to eq("goodbye")
    end

  end

  context "raises an error", :sqlite3 => :only do

    it "when creating a record with DB_DEFAULT" do
      expect { User.create!(:alpha => ActiveRecord::DB_DEFAULT, :beta => "hello") }.to raise_error ActiveRecord::StatementInvalid
    end

    it "when updating a record with DB_DEFAULT" do
      u = User.create!(:alpha => "hey", :beta => "hello")
      expect { u.update_attributes(:alpha => ActiveRecord::DB_DEFAULT, :beta => "goodbye") }.to raise_error ActiveRecord::StatementInvalid
    end
  end

  protected

  def create_table(model, columns_with_options)
    migration.suppress_messages do
      migration.create_table model.table_name, :force => true do |t|
        columns_with_options.each_pair do |column, options|
          t.send :string, column, options
        end
      end
      model.reset_column_information
    end
  end
end

