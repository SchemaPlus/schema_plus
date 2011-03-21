# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'models/post'
require 'models/comment'

describe ActiveRecord::Migration do

  it "should respond to get_references" do
    ActiveRecord::Migration.should respond_to :get_references
  end

end

describe ActiveRecord::Migration do
  include ActiveSchemaHelpers

  before(:all) do
    load_auto_schema
  end

  context "when table is created" do

    before(:each) do
      @model = Post
    end

    it "should create foreign keys" do
      create_table(@model,  :user_id => {}, 
                          :author_id => { :references => :users },
                          :member_id => { :references => nil } )
      @model.should reference(:users, :id).on(:user_id)
      @model.should reference(:users, :id).on(:author_id)
      @model.should_not reference.on(:member_id)
    end

    it "should use default on_cascade action" do
      ActiveSchema.config.foreign_keys.on_update = :cascade
      create_table(@model, :user_id => {})
      ActiveSchema.config.foreign_keys.on_update = nil
      @model.should reference.on(:user_id).on_update(:cascade) 
    end

    it "should use default on_cascade action" do
      ActiveSchema.config.foreign_keys.on_delete = :cascade
      create_table(@model, :user_id => {})
      ActiveSchema.config.foreign_keys.on_delete = nil
      @model.should reference.on(:user_id).on_delete(:cascade) 
    end

    it "should create an index if specified on column" do
      create_table(@model, :state => { :index => true }) 
      @model.should have_index.on(:state)
    end

    it "should create an index if specified explicitly" do
      create_table_opts(@model, {}, {:state => {}}, {:state => {}}) 
      @model.should have_index.on(:state)
    end

    it "should create a unique index if specified explicitly" do
      create_table_opts(@model, {}, {:state => {}}, {:state => {:unique => true}}) 
      @model.should have_unique_index.on(:state)
    end

    it "should create a multiple-column index if specified" do
      create_table(@model, :city => {},
                   :state => { :index => {:with => :city} } ) 
      @model.should have_index.on([:state, :city])
    end
    
    it "should auto-index foreign keys only" do
      with_fk_config(:auto_index => true) do
        create_table(@model,  :user_id => {},
                     :application_id => { :references => nil },
                     :state => {})
        @model.should have_index.on(:user_id)
        @model.should_not have_index.on(:application_id)
        @model.should_not have_index.on(:state)
      end
    end

    it "should override foreign key auto_create positively" do
      with_fk_config(:auto_create => false) do
        create_table_opts(@model, {:foreign_keys => {:auto_create => true}}, :user_id => {})
        @model.should reference(:users, :id).on(:user_id)
      end
    end

    it "should override foreign key auto_create negatively" do
      with_fk_config(:auto_create => true) do
        create_table_opts(@model, {:foreign_keys => {:auto_create => false}}, :user_id => {})
        @model.should_not reference.on(:user_id)
      end
    end

    it "should override foreign key auto_index positively" do
      with_fk_config(:auto_index => false) do 
        create_table_opts(@model, {:foreign_keys => {:auto_index => true}}, :user_id => {})
        @model.should have_index.on(:user_id)
      end
    end

    it "should raise an error for an invalid on_update action" do
        expect { create_table(@model, :user_id => {:on_update => :invalid}) }.should raise_error(ArgumentError)
    end

    it "should raise an error for an invalid on_delete action" do
        expect { create_table(@model, :user_id => {:on_delete => :invalid}) }.should raise_error(ArgumentError)
    end

    unless ActiveSchemaHelpers.mysql?
      it "should override foreign key auto_index negatively" do
        with_fk_config(:auto_index => true) do 
          create_table_opts(@model, {:foreign_keys => {:auto_index => false}}, :user_id => {})
          @model.should_not have_index.on(:user_id)
        end
      end

      it "should disable auto-index for a column" do
        with_fk_config(:auto_index => true) do
          create_table(@model,  :user_id => { :index => false })
          @model.should_not have_index.on(:user_id)
        end
      end

    end

  end

  unless ActiveSchemaHelpers.sqlite3?

    context "when column is added" do

      before(:each) do
        @model = Comment
      end

      it "should create foreign key" do
        add_column(:post_id, :integer) do
          @model.should reference(:posts, :id).on(:post_id)
        end
      end

      it "should create foreign key to explicity given table" do
        add_column(:author_id, :integer, :references => :users) do
          @model.should reference(:users, :id).on(:author_id)
        end
      end

      it "should create foreign key to explicity given table and column name" do
        add_column(:author_login, :string, :references => [:users, :login]) do 
          @model.should reference(:users, :login).on(:author_login) 
        end
      end

      it "should create foreign key to the same table on parent_id" do
        add_column(:parent_id, :integer) do
          @model.should reference(@model.table_name, :id).on(:parent_id)
        end
      end

      it "shouldn't create foreign key if column doesn't look like foreign key" do
        add_column(:views_count, :integer) do
          @model.should_not reference.on(:views_count)
        end
      end

      it "shouldnt't create foreign key if specified explicity" do
        add_column(:post_id, :integer, :references => nil) do
          @model.should_not reference.on(:post_id)
        end
      end

      it "should create an index if specified" do
        add_column(:post_id, :integer, :index => true) do
          @model.should have_index.on(:post_id)
        end
      end

      it "should create a unique index if specified" do
        add_column(:post_id, :integer, :index => { :unique => true }) do
          @model.should have_unique_index.on(:post_id)
        end
      end

      it "should allow custom name for index" do
        index_name = 'comments_post_id_unique_index'
        add_column(:post_id, :integer, :index => { :unique => true, :name => index_name }) do
          @model.should have_unique_index(:name => index_name).on(:post_id)
        end
      end

      it "should auto-index if specified in global options" do
        ActiveSchema.config.foreign_keys.auto_index = true
        add_column(:post_id, :integer) do
          @model.should have_index.on(:post_id)
        end
        ActiveSchema.config.foreign_keys.auto_index = false
      end

      it "should auto-index foreign keys only" do
        ActiveSchema.config.foreign_keys.auto_index = true
        add_column(:state, :integer) do
          @model.should_not have_index.on(:state)
        end
        ActiveSchema.config.foreign_keys.auto_index = false
      end

      it "should allow to overwrite auto_index options in column definition" do
        ActiveSchema.config.foreign_keys.auto_index = true
        add_column(:post_id, :integer, :index => false) do
          # MySQL creates an index on foreign by default
          # and we can do nothing with that
          unless ActiveSchemaHelpers.mysql?
            @model.should_not have_index.on(:post_id)
          end
        end
        ActiveSchema.config.foreign_keys.auto_index = false
      end

      it "should use default on_update action" do
        ActiveSchema.config.foreign_keys.on_update = :cascade
        add_column(:post_id, :integer) do
          @model.should reference.on(:post_id).on_update(:cascade) 
        end
        ActiveSchema.config.foreign_keys.on_update = nil
      end

      it "should use default on_delete action" do
        ActiveSchema.config.foreign_keys.on_delete = :cascade
        add_column(:post_id, :integer) do
          @model.should reference.on(:post_id).on_delete(:cascade) 
        end
        ActiveSchema.config.foreign_keys.on_delete = nil
      end

      it "should allow to overwrite default actions" do
        ActiveSchema.config.foreign_keys.on_delete = :cascade
        ActiveSchema.config.foreign_keys.on_update = :restrict
        add_column(:post_id, :integer, :on_update => :set_null, :on_delete => :set_null) do
          @model.should reference.on(:post_id).on_delete(:set_null).on_update(:set_null)
        end
        ActiveSchema.config.foreign_keys.on_delete = nil
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
        change_column :user, :string, :references => [:users, :login]
        @model.should reference(:users, :login).on(:user)
        change_column :user, :string, :references => nil
      end

      context "and initially references to users table" do

        it "should have foreign key" do
          @model.should reference(:users)
        end

        it "should drop foreign key afterwards" do
          change_column :user_id, :integer, :references => :members
          @model.should_not reference(:users)
          change_column :user_id, :integer, :references => :users
        end

        it "should reference pointed table afterwards" do
          change_column :user_id, :integer, :references => :members
          @model.should reference(:members)
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
  end
    
  def foreign_key(model, column)
    columns = Array(column).collect(&:to_s)
    model.foreign_keys.detect { |fk| fk.table_name == model.table_name && fk.column_names == columns } 
  end

  def create_table_opts(model, table_options, columns_with_options, indexes={})
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table model.table_name, table_options.merge(:force => true) do |t|
        columns_with_options.each_pair do |column, options|
          t.integer column, options
        end
        indexes.each_pair do |column, options|
          t.index column, options
        end
      end
      model.reset_column_information
    end
  end

  def create_table(model, columns_with_options)
    create_table_opts(model, {}, columns_with_options)
  end

  def with_fk_config(opts, &block)
    save = Hash[opts.keys.collect{|key| [key, ActiveSchema.config.foreign_keys.send(key)]}]
    begin
      ActiveSchema.config.foreign_keys.update_attributes(opts)
      yield
    ensure
      ActiveSchema.config.foreign_keys.update_attributes(save)
    end
  end


end

