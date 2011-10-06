module SchemaPlus::ActiveRecord
  module ForeignKeys
    include SchemaPlus::ActiveRecord::ColumnOptionsHandler

    # Enhances ActiveRecord::ConnectionAdapters::AbstractAdapter#add_column to support indexes and foreign keys, with automatic creation
    #
    # == Indexes
    #
    # The <tt>:index</tt> option takes a hash of parameters to pass to ActiveRecord::Migration.add_index.  Thus
    #
    #    add_column('books', 'isbn', :string, :index => {:name => "ISBN-index", :unique => true })
    # 
    # is equivalent to:
    #
    #    add_column('books', 'isbn', :string)
    #    add_index('books', ['isbn'], :name => "ISBN-index", :unique => true)
    #
    #
    # In order to support multi-column indexes, an special parameter <tt>:with</tt> may be specified, which takes another column name or an array of column names to include in the index.  Thus
    #
    #    add_column('contacts', 'phone_number', :string, :index => { :with => [:country_code, :area_code], :unique => true })
    # 
    # is equivalent to:
    #
    #    add_column('contacts', 'phone_number', :string)
    #    add_index('contacts', ['phone_number', 'country_code', 'area_code'], :unique => true)
    #
    #
    # Some convenient shorthands are available:
    #
    #    add_column('books', 'isbn', :index => true) # adds index with no extra options
    #    add_column('books', 'isbn', :index => :unique) # adds index with :unique => true
    #
    # == Foreign Key Constraints
    #
    # The +:references+ option takes the name of a table to reference in
    # a foreign key constraint.  For example:
    #
    #    add_column('widgets', 'color', :integer, :references => 'colors')
    #
    # is equivalent to
    #
    #    add_column('widgets', 'color', :integer)
    #    add_foreign_key('widgets', 'color', 'colors', 'id')
    #
    # The foreign column name defaults to +id+, but a different column
    # can be specified using <tt>:references => [table_name,column_name]</tt>
    #
    # Additional options +:on_update+ and +:on_delete+ can be spcified,
    # with values as described at ConnectionAdapters::ForeignKeyDefinition.  For example:
    #
    #     add_column('comments', 'post', :integer, :references => 'posts', :on_delete => :cascade)
    #
    # Global default values for +:on_update+ and +:on_delete+ can be
    # specified in SchemaPlus.steup via, e.g., <tt>config.foreign_keys.on_update = :cascade</tt>
    #
    # == Automatic Foreign Key Constraints
    #
    # SchemaPlus supports the convention of naming foreign key columns
    # with a suffix of +_id+.   That is, if you define a column suffixed
    # with +_id+, SchemaPlus assumes an implied :references to a table
    # whose name is the column name prefix, pluralized.  For example,
    # these are equivalent:
    #
    #     add_column('posts', 'author_id', :integer)
    #     add_column('posts', 'author_id', :integer, :references => 'authors')
    #
    # As a special case, if the column is named 'parent_id', SchemaPlus
    # assumes it's a self reference, for a record that acts as a node of
    # a tree.  Thus, these are equivalent:
    #
    #     add_column('sections', 'parent_id', :integer)
    #     add_column('sections', 'parent_id', :integer, :references => 'sections')
    #      
    # If the implicit +:references+ value isn't what you want (e.g., the
    # table name isn't pluralized), you can explicitly specify
    # +:references+ and it will override the implicit value.
    #
    # If you don't want a foreign key constraint to be created, specify
    # <tt>:references => nil</tt>.
    # To disable automatic foreign key constraint creation globally, set
    # <tt>config.foreign_keys.auto_create = false</tt> in
    # SchemaPlus.steup.
    #
    # == Automatic Foreign Key Indexes
    #
    # Since efficient use of foreign key constraints requires that the
    # referencing column be indexed, SchemaPlus will automatically create
    # an index for the column if it created a foreign key.  Thus
    #
    #    add_column('widgets', 'color', :integer, :references => 'colors')
    #
    # is equivalent to:
    #
    #    add_column('widgets', 'color', :integer, :references => 'colors', :index => true)
    #
    # If you want to pass options to the index, you can explcitly pass
    # index options, such as <tt>:index => :unique</tt>. 
    #
    # If you don't want an index to be created, specify
    # <tt>:index => nil</tt>.
    # To disable automatic foreign key index creation globally, set
    # <tt>config.foreign_keys.auto_index = false</tt> in
    # SchemaPlus.steup.  (*Note*: If you're using MySQL, it will
    # automatically create an index for foreign keys if you don't.)
    #
    def add_column(table_name, column_name, type, options = {})
      super
      schema_plus_handle_column_options(table_name, column_name, options)
    end

    # Enhances ActiveRecord::Migration#change_column to support indexes and foreign keys same as add_column.
    def change_column(table_name, column_name, type, options = {})
      super
      remove_foreign_key_if_exists(table_name, column_name)
      schema_plus_handle_column_options(table_name, column_name, options)
    end

    protected
    def remove_foreign_key_if_exists(table_name, column_name) #:nodoc:
      foreign_keys = ActiveRecord::Base.connection.foreign_keys(table_name.to_s)
      fk = foreign_keys.detect { |fk| fk.table_name == table_name.to_s && fk.column_names == Array(column_name).collect(&:to_s) }
      remove_foreign_key(table_name, fk.name) if fk
    end

  end
end
