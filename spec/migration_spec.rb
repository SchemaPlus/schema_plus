# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ActiveRecord::Migration do
  include SchemaPlusHelpers

  before(:each) do
    define_schema(:auto_create => true) do

      create_table :users, :force => true do |t|
        t.string :login, :index => { :unique => true }
      end

      create_table :members, :force => true do |t|
        t.string :login
      end

      create_table :comments, :force => true do |t|
        t.string :content
        t.integer :user
        t.integer :user_id
        t.foreign_key :user_id, :users, :id
      end

      create_table :posts, :force => true do |t|
        t.string :content
      end
    end
    class User < ::ActiveRecord::Base ; end
    class Post < ::ActiveRecord::Base ; end
    class Comment < ::ActiveRecord::Base ; end
  end

  around(:each) do |example|
    with_fk_config(:auto_create => true, :auto_index => true) { example.run }
  end

  context "when table is created" do

    before(:each) do
      @model = Post
    end

    it "should properly handle default values for booleans" do
      expect {
        recreate_table(@model) do |t|
         t.boolean :bool, :default => true
        end
      }.to_not raise_error
      expect(@model.create.reload.bool).to be true
    end

    it "should create auto foreign keys" do
      recreate_table(@model) do |t|
        t.integer :user_id
      end
      expect(@model).to reference(:users, :id).on(:user_id)
    end

    it "should create explicit foreign key with default reference" do
      recreate_table(@model) do |t|
        t.integer :user, :foreign_key => true
      end
      expect(@model).to reference(:users, :id).on(:user)
    end

    it "should create foreign key with different reference" do
      recreate_table(@model) do |t|
        t.integer :author_id, :foreign_key => { :references => :users }
      end
      expect(@model).to reference(:users, :id).on(:author_id)
    end

    it "should create foreign key with different reference using shortcut" do
      recreate_table(@model) do |t|
        t.integer :author_id, :references => :users
      end
      expect(@model).to reference(:users, :id).on(:author_id)
    end

    it "should create foreign key with default name" do
      recreate_table @model do |t|
        t.integer :user_id, :foreign_key => true
      end
      expect(@model).to reference(:users, :id).with_name("fk_#{@model.table_name}_user_id")
    end

    it "should create foreign key with specified name" do
      recreate_table @model do |t|
        t.integer :user_id, :foreign_key => { :name => "wugga" }
      end
      expect(@model).to reference(:users, :id).with_name("wugga")
    end

    it "should suppress foreign key" do
      recreate_table(@model) do |t|
        t.integer :member_id, :foreign_key => false
      end
      expect(@model).not_to reference.on(:member_id)
    end

    it "should suppress foreign key using shortcut" do
      recreate_table(@model) do |t|
        t.integer :member_id, :references => nil
      end
      expect(@model).not_to reference.on(:member_id)
    end

    it "should create foreign key using t.belongs_to" do
      recreate_table(@model) do |t|
        t.belongs_to :user
      end
      expect(@model).to reference(:users, :id).on(:user_id)
    end

    it "should not create foreign key using t.belongs_to with :polymorphic => true" do
      recreate_table(@model) do |t|
        t.belongs_to :user, :polymorphic => true
      end
      expect(@model).not_to reference(:users, :id).on(:user_id)
    end

    it "should create foreign key using t.references" do
      recreate_table(@model) do |t|
        t.references :user
      end
      expect(@model).to reference(:users, :id).on(:user_id)
    end

    it "should not create foreign key using t.references with :foreign_key => false" do
      recreate_table(@model) do |t|
        t.references :user, :foreign_key => false
      end
      expect(@model).not_to reference(:users, :id).on(:user_id)
    end

    it "should not create foreign key using t.references with :polymorphic => true" do
      recreate_table(@model) do |t|
        t.references :user, :polymorphic => true
      end
      expect(@model).not_to reference(:users, :id).on(:user_id)
    end

    it "should create foreign key to the same table on parent_id" do
      recreate_table(@model) do |t|
        t.integer :parent_id
      end
      expect(@model).to reference(@model.table_name, :id).on(:parent_id)
    end

    it "should create an index if specified on column" do
      recreate_table(@model) do |t|
        t.integer :state, :index => true
      end
      expect(@model).to have_index.on(:state)
    end

    it "should create a unique index if specified on column" do
      recreate_table(@model) do |t|
        t.integer :state, :index => { :unique => true }
      end
      expect(@model).to have_unique_index.on(:state)
    end

    it "should create a unique index if specified on column using shorthand" do
      recreate_table(@model) do |t|
        t.integer :state, :index => :unique
      end
      expect(@model).to have_unique_index.on(:state)
    end

    [:references, :belongs_to].each do |reftype|

      context "when define #{reftype}" do

        before(:each) do
          @model = Comment
        end

        it "should create foreign key" do
          create_reference(reftype, :post)
          expect(@model).to reference(:posts, :id).on(:post_id)
        end

        it "should not create a foreign_key if polymorphic" do
          create_reference(reftype, :post, :polymorphic => true)
          expect(@model).not_to reference(:posts, :id).on(:post_id)
        end

        it "should create an index implicitly" do
          create_reference(reftype, :post)
          expect(@model).to have_index.on(:post_id)
        end

        it "should create exactly one index explicitly (#157)" do
          create_reference(reftype, :post, :index => true)
          expect(@model).to have_index.on(:post_id)
        end

        it "should respect :unique (#157)" do
          create_reference(reftype, :post, :index => :unique)
          expect(@model).to have_unique_index.on(:post_id)
        end

        it "should create a two-column index if polymophic and index requested" do
          create_reference(reftype, :post, :polymorphic => true, :index => true)
          expect(@model).to have_index.on([:post_id, :post_type])
        end unless ::ActiveRecord::VERSION::MAJOR.to_i < 4

        protected

        def create_reference(reftype, column_name, *args)
          recreate_table(@model) do |t|
            t.send reftype, column_name, *args
          end
        end

      end
    end

    if SchemaPlusHelpers.mysql?
      it "should pass index length option properly" do
        recreate_table(@model) do |t|
          t.string :foo
          t.string :bar, :index => { :with => :foo, :length => { :foo => 8, :bar => 12 }}
        end
        index = @model.indexes.first
        expect(Hash[index.columns.zip(index.lengths.map(&:to_i))]).to eq({ "foo" => 8, "bar" => 12})
      end
    end

    it "should create an index if specified explicitly" do
      recreate_table(@model) do |t|
        t.integer :state
        t.index :state
      end
      expect(@model).to have_index.on(:state)
    end

    it "should create a unique index if specified explicitly" do
      recreate_table(@model) do |t|
        t.integer :state
        t.index :state, :unique => true
      end
      expect(@model).to have_unique_index.on(:state)
    end

    it "should create a multiple-column index if specified" do
      recreate_table(@model) do |t|
        t.integer :city
        t.integer :state,       :index => { :with => :city }
      end
      expect(@model).to have_index.on([:state, :city])
    end

    it "should auto-index foreign keys only" do
      recreate_table(@model) do |t|
        t.integer :user_id
        t.integer :application_id, :references => nil
        t.integer :state
      end
      expect(@model).to have_index.on(:user_id)
      expect(@model).not_to have_index.on(:application_id)
      expect(@model).not_to have_index.on(:state)
    end

    it "should override foreign key auto_create positively" do
      with_fk_config(:auto_create => false) do
        recreate_table @model, :foreign_keys => {:auto_create => true} do |t|
          t.integer :user_id
        end
        expect(@model).to reference(:users, :id).on(:user_id)
      end
    end

    it "should override foreign key auto_create negatively" do
      with_fk_config(:auto_create => true) do
        recreate_table @model, :foreign_keys => {:auto_create => false} do |t|
          t.integer :user_id
        end
        expect(@model).not_to reference.on(:user_id)
      end
    end

    it "should override foreign key auto_index positively" do
      with_fk_config(:auto_index => false) do
        recreate_table @model, :foreign_keys => {:auto_index => true} do |t|
          t.integer :user_id
        end
        expect(@model).to have_index.on(:user_id)
      end
    end

    actions = [:cascade, :restrict, :set_null, :set_default, :no_action]

    if SchemaPlusHelpers.mysql?
      actions.delete(:set_default)
      it "should raise a not-implemented error for on_update => :set_default" do
        expect {
          recreate_table @model do |t|
            t.integer :user_id, :foreign_key => { :on_update => :set_default }
          end
        }.to raise_error(NotImplementedError)
      end

      it "should raise a not-implemented error for on_delete => :set_default" do
        expect {
          recreate_table @model do |t|
            t.integer :user_id, :foreign_key => { :on_delete => :set_default }
          end
        }.to raise_error(NotImplementedError)
      end
    end

    actions.each do |action|
      it "should create and detect on_update #{action.inspect}" do
        recreate_table @model do |t|
          t.integer :user_id,   :foreign_key => { :on_update => action }
        end
        expect(@model).to reference.on(:user_id).on_update(action)
      end

      it "should create and detect on_update #{action.inspect} using shortcut" do
        recreate_table @model do |t|
          t.integer :user_id,   :on_update => action
        end
        expect(@model).to reference.on(:user_id).on_update(action)
      end

      it "should create and detect on_delete #{action.inspect}" do
        recreate_table @model do |t|
          t.integer :user_id,   :foreign_key => { :on_delete => action }
        end
        expect(@model).to reference.on(:user_id).on_delete(action)
      end

      it "should create and detect on_delete #{action.inspect} using shortcut" do
        recreate_table @model do |t|
          t.integer :user_id,   :on_delete => action
        end
        expect(@model).to reference.on(:user_id).on_delete(action)
      end
    end

    [false, true, :initially_deferred].each do |status|
      it "should create and detect deferrable #{status.inspect}" do
        recreate_table @model do |t|
          t.integer :user_id,   :on_delete => :cascade, :deferrable => status
        end
        expect(@model).to reference.on(:user_id).deferrable(status)
      end
    end unless SchemaPlusHelpers.mysql?

    it "should use default on_delete action" do
      with_fk_config(:on_delete => :cascade) do
        recreate_table @model do |t|
          t.integer :user_id
        end
        expect(@model).to reference.on(:user_id).on_delete(:cascade)
      end
    end

    it "should override on_update action per table" do
      with_fk_config(:on_update => :cascade) do
        recreate_table @model, :foreign_keys => {:on_update => :restrict} do |t|
          t.integer :user_id
        end
        expect(@model).to reference.on(:user_id).on_update(:restrict)
      end
    end

    it "should override on_delete action per table" do
      with_fk_config(:on_delete => :cascade) do
        recreate_table @model, :foreign_keys => {:on_delete => :restrict} do |t|
          t.integer :user_id
        end
        expect(@model).to reference.on(:user_id).on_delete(:restrict)
      end
    end

    it "should override on_update action per column" do
      with_fk_config(:on_update => :cascade) do
        recreate_table @model, :foreign_keys => {:on_update => :restrict} do |t|
          t.integer :user_id, :foreign_key => { :on_update => :set_null }
        end
        expect(@model).to reference.on(:user_id).on_update(:set_null)
      end
    end

    it "should override on_delete action per column" do
      with_fk_config(:on_delete => :cascade) do
        recreate_table @model, :foreign_keys => {:on_delete => :restrict} do |t|
          t.integer :user_id, :foreign_key => { :on_delete => :set_null }
        end
        expect(@model).to reference.on(:user_id).on_delete(:set_null)
      end
    end

    it "should raise an error for an invalid on_update action" do
      expect {
        recreate_table @model do |t|
          t.integer :user_id, :foreign_key => { :on_update => :invalid }
        end
      }.to raise_error(ArgumentError)
    end

    it "should raise an error for an invalid on_delete action" do
      expect {
        recreate_table @model do |t|
        t.integer :user_id, :foreign_key => { :on_delete => :invalid }
        end
      }.to raise_error(ArgumentError)
    end

    unless SchemaPlusHelpers.mysql?
      it "should override foreign key auto_index negatively" do
        with_fk_config(:auto_index => true) do
          recreate_table @model, :foreign_keys => {:auto_index => false} do |t|
            t.integer :user_id
          end
          expect(@model).not_to have_index.on(:user_id)
        end
      end

      it "should disable auto-index for a column" do
        with_fk_config(:auto_index => true) do
          recreate_table @model do |t|
            t.integer :user_id, :index => false
          end
          expect(@model).not_to have_index.on(:user_id)
        end
      end

    end

  end

  context "when table is changed" do
    before(:each) do
      @model = Post
    end
    [false, true].each do |bulk|
      suffix = bulk ? ' with :bulk option' : ""

      it "should create an index if specified on column"+suffix do
        change_table(@model, :bulk => bulk) do |t|
          t.integer :state, :index => true
        end
        expect(@model).to have_index.on(:state)
      end

      unless SchemaPlusHelpers.sqlite3?

        it "should create a foreign key constraint"+suffix do
          change_table(@model, :bulk => bulk) do |t|
            t.integer :user_id
          end
          expect(@model).to reference(:users, :id).on(:user_id)
        end

        context "migrate down" do
          it "should remove a foreign key constraint"+suffix do
            Comment.reset_column_information
            expect(Comment).to reference(:users, :id).on(:user_id)
            migration = Class.new ::ActiveRecord::Migration do
              define_method(:change) {
                change_table("comments", :bulk => bulk) do |t|
                  t.integer :user_id
                end
              }
            end
            ActiveRecord::Migration.suppress_messages do
              migration.migrate(:down)
            end
            Comment.reset_column_information
            expect(Comment).not_to reference(:users, :id).on(:user_id)
          end
        end if ActiveRecord::VERSION::MAJOR >= 4

        it "should create a foreign key constraint using :references"+suffix do
          change_table(@model, :bulk => bulk) do |t|
            t.references :user
          end
          expect(@model).to reference(:users, :id).on(:user_id)
        end

        it "should create a foreign key constraint using :belongs_to"+suffix do
          change_table(@model, :bulk => bulk) do |t|
            t.belongs_to :user
          end
          expect(@model).to reference(:users, :id).on(:user_id)
        end
      end
    end
  end


  unless SchemaPlusHelpers.sqlite3?

    context "when column is added" do

      before(:each) do
        @model = Comment
      end

      it "should create an index" do
        add_column(:slug, :string, :index => true) do
          expect(@model).to have_index.on(:slug)
        end
      end

      it "should create foreign key" do
        add_column(:post_id, :integer) do
          expect(@model).to reference(:posts, :id).on(:post_id)
        end
      end

      it "should create foreign key to explicitly given table" do
        add_column(:author_id, :integer, :foreign_key => { :references => :users }) do
          expect(@model).to reference(:users, :id).on(:author_id)
        end
      end

      it "should create foreign key to explicitly given table using shortcut" do
        add_column(:author_id, :integer, :references => :users) do
          expect(@model).to reference(:users, :id).on(:author_id)
        end
      end

      it "should create foreign key to explicitly given table and column name" do
        add_column(:author_login, :string, :foreign_key => { :references => [:users, :login]}) do
          expect(@model).to reference(:users, :login).on(:author_login)
        end
      end

      it "should create foreign key to the same table on parent_id" do
        add_column(:parent_id, :integer) do
          expect(@model).to reference(@model.table_name, :id).on(:parent_id)
        end
      end

      it "shouldn't create foreign key if column doesn't look like foreign key" do
        add_column(:views_count, :integer) do
          expect(@model).not_to reference.on(:views_count)
        end
      end

      it "shouldn't create foreign key if specified explicitly" do
        add_column(:post_id, :integer, :foreign_key => false) do
          expect(@model).not_to reference.on(:post_id)
        end
      end

      it "shouldn't create foreign key if specified explicitly by shorthand" do
        add_column(:post_id, :integer, :references => nil) do
          expect(@model).not_to reference.on(:post_id)
        end
      end

      it "should create an index if specified" do
        add_column(:post_id, :integer, :index => true) do
          expect(@model).to have_index.on(:post_id)
        end
      end

      it "should create a unique index if specified" do
        add_column(:post_id, :integer, :index => { :unique => true }) do
          expect(@model).to have_unique_index.on(:post_id)
        end
      end

      it "should create a unique index if specified by shorthand" do
        add_column(:post_id, :integer, :index => :unique) do
          expect(@model).to have_unique_index.on(:post_id)
        end
      end

      it "should allow custom name for index" do
        index_name = 'comments_post_id_unique_index'
        add_column(:post_id, :integer, :index => { :unique => true, :name => index_name }) do
          expect(@model).to have_unique_index(:name => index_name).on(:post_id)
        end
      end

      it "should auto-index if specified in global options" do
        SchemaPlus.config.foreign_keys.auto_index = true
        add_column(:post_id, :integer) do
          expect(@model).to have_index.on(:post_id)
        end
        SchemaPlus.config.foreign_keys.auto_index = false
      end

      it "should auto-index foreign keys only" do
        SchemaPlus.config.foreign_keys.auto_index = true
        add_column(:state, :integer) do
          expect(@model).not_to have_index.on(:state)
        end
        SchemaPlus.config.foreign_keys.auto_index = false
      end

      it "should allow to overwrite auto_index options in column definition" do
        SchemaPlus.config.foreign_keys.auto_index = true
        add_column(:post_id, :integer, :index => false) do
          # MySQL creates an index on foreign by default
          # and we can do nothing with that
          unless SchemaPlusHelpers.mysql?
            expect(@model).not_to have_index.on(:post_id)
          end
        end
        SchemaPlus.config.foreign_keys.auto_index = false
      end

      it "should use default on_update action" do
        SchemaPlus.config.foreign_keys.on_update = :cascade
        add_column(:post_id, :integer) do
          expect(@model).to reference.on(:post_id).on_update(:cascade)
        end
        SchemaPlus.config.foreign_keys.on_update = nil
      end

      it "should use default on_delete action" do
        SchemaPlus.config.foreign_keys.on_delete = :cascade
        add_column(:post_id, :integer) do
          expect(@model).to reference.on(:post_id).on_delete(:cascade)
        end
        SchemaPlus.config.foreign_keys.on_delete = nil
      end

      it "should allow to overwrite default actions" do
        SchemaPlus.config.foreign_keys.on_delete = :cascade
        SchemaPlus.config.foreign_keys.on_update = :restrict
        add_column(:post_id, :integer, :foreign_key => { :on_update => :set_null, :on_delete => :set_null}) do
          expect(@model).to reference.on(:post_id).on_delete(:set_null).on_update(:set_null)
        end
        SchemaPlus.config.foreign_keys.on_delete = nil
      end

      protected
      def add_column(column_name, *args)
        table = @model.table_name
        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Migration.add_column(table, column_name, *args)
          @model.reset_column_information
          yield if block_given?
          ActiveRecord::Migration.remove_column(table, column_name)
        end
      end

    end


    context "when column is changed" do

      before(:each) do
        @model = Comment
      end

      it "should create foreign key" do
        change_column :user, :string, :foreign_key => { :references => [:users, :login] }
        expect(@model).to reference(:users, :login).on(:user)
      end

      context "and initially references to users table" do

        before(:each) do
          recreate_table @model do |t|
            t.integer :user_id
          end
        end

        it "should have foreign key" do
          expect(@model).to reference(:users)
        end

        it "should drop foreign key if it is no longer valid" do
          change_column :user_id, :integer, :foreign_key => { :references => :members }
          expect(@model).not_to reference(:users)
        end

        it "should drop foreign key if requested to do so" do
          change_column :user_id, :integer, :foreign_key => { :references => nil }
          expect(@model).not_to reference(:users)
        end

        it "should remove auto-created index if foreign key is removed" do
          expect(@model).to have_index.on(:user_id)  # sanity check that index was auto-created
          change_column :user_id, :integer, :foreign_key => { :references => nil }
          expect(@model).not_to have_index.on(:user_id)
        end

        it "should reference pointed table afterwards if new one is created" do
          change_column :user_id, :integer, :foreign_key => { :references => :members }
          expect(@model).to reference(:members)
        end

        it "should maintain foreign key if it's unaffected by change" do
          change_column :user_id, :integer, :default => 0
          expect(@model).to reference(:users)
        end

        it "should maintain foreign key if it's unaffected by change, even if auto_index is off" do
          with_fk_config(:auto_create => false) do
            change_column :user_id, :integer, :default => 0
            expect(@model).to reference(:users)
          end
        end

      end

      context "if column defined without foreign key but with index" do
        before(:each) do
          recreate_table @model do |t|
            t.integer :user_id, :foreign_key => false, :index => true
          end
        end

        it "should create the index" do
          expect(@model).to have_index.on(:user_id)
        end

        it "adding foreign key should not fail due to attempt to auto-create existing index" do
          expect { change_column :user_id, :integer, :foreign_key => true }.to_not raise_error
        end
      end

      protected
      def change_column(column_name, *args)
        table = @model.table_name
        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Migration.change_column(table, column_name, *args)
          @model.reset_column_information
        end
      end

    end

    context "when column is removed" do
      before(:each) do
        @model = Comment
        recreate_table @model do |t|
          t.integer :post_id
        end
      end

      it "should remove a foreign key" do
        expect(@model).to reference(:posts)
        remove_column(:post_id)
        expect(@model).not_to reference(:posts)
      end

      it "should remove an index" do
        expect(@model).to have_index.on(:post_id)
        remove_column(:post_id)
        expect(@model).not_to have_index.on(:post_id)
      end

      protected
      def remove_column(column_name)
        table = @model.table_name
        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Migration.remove_column(table, column_name)
          @model.reset_column_information
        end
      end
    end

  end

  context "when table is renamed" do

    before(:each) do
      @model = Comment
      recreate_table @model do |t|
        t.integer :user_id
        t.integer :xyz, :index => true
      end
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.rename_table @model.table_name, :newname
      end
    end

    around(:each) do |example|
      begin
        example.run
      ensure
        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Migration.rename_table :newname, :comments
        end
      end
    end

    it "should rename rails-named indexes" do
      index = ActiveRecord::Base.connection.indexes(:newname).find{|index| index.columns == ['xyz']}
      expect(index.name).to match(/^index_newname_on/)
    end

    it "should rename fk indexes" do
      index = ActiveRecord::Base.connection.indexes(:newname).find{|index| index.columns == ['user_id']}
      expect(index.name).to match(/^fk__newname_/)
    end

    unless SchemaPlusHelpers.sqlite3?
      it "should rename foreign key constraints" do
        expect(ActiveRecord::Base.connection.foreign_keys(:newname).first.name).to match(/newname/)
      end
    end

  end

  unless SchemaPlusHelpers.sqlite3?

    context "when table with more than one fk constraint is renamed" do

      before(:each) do
        @model = Comment
        recreate_table @model do |t|
          t.integer :user_id
          t.integer :member_id
        end
        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Migration.rename_table @model.table_name, :newname
        end
      end

      around(:each) do |example|
        begin
          example.run
        ensure
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Migration.rename_table :newname, :comments
          end
        end
      end
      it "should rename foreign key constraints" do
        names = ActiveRecord::Base.connection.foreign_keys(:newname).map(&:name)
        expect(names.grep(/newname/)).to eq(names)
      end
    end

  end

  def recreate_table(model, opts={}, &block)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table model.table_name, opts.merge(:force => true), &block
    end
    model.reset_column_information
  end

  def change_table(model, opts={}, &block)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.change_table model.table_name, opts, &block
    end
    model.reset_column_information
  end

end

