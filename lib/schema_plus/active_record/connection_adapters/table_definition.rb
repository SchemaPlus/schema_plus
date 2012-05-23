module SchemaPlus::ActiveRecord::ConnectionAdapters

  #
  # SchemaPlus adds several methods to TableDefinition, allowing indexes
  # and foreign key constraints to be defined within a
  # <tt>create_table</tt> block of a migration, allowing for better
  # encapsulation and more DRY definitions.
  #
  # For example, without SchemaPlus you might define a table like this:
  #
  #    create_table :widgets do |t|
  #       t.string :name
  #    end
  #    add_index :widgets, :name
  #
  # But with SchemaPlus, the index can be defined within the create_table
  # block, so you don't need to repeat the table name:
  #
  #    create_table :widgets do |t|
  #       t.string :name
  #       t.index :name
  #    end
  #
  # Even more DRY, you can define the index as part of the column
  # definition, via:
  #
  #   create_table :widgets do |t|
  #      t.string :name, :index => true
  #   end
  #
  # For details about the :index option (including unique and multi-column indexes), see the
  # documentation for Migration::ClassMethods#add_column
  #
  # SchemaPlus also supports creation of foreign key constraints analogously, using Migration::ClassMethods#add_foreign_key or TableDefinition#foreign_key or as part of the column definition, for example:
  #
  #    create_table :posts do |t|  # not DRY
  #       t.integer :author_id    
  #    end
  #    add_foreign_key :posts, :author_id, :references => :authors
  #
  #    create_table :posts do |t|  # DRYer
  #       t.integer :author_id
  #       t.foreign_key :author_id, :references => :authors
  #    end
  #
  #    create_table :posts do |t|  # Dryest
  #       t.integer :author_id, :references => :authors
  #    end
  #
  # <b>NOTE:</b> In the standard configuration, SchemaPlus automatically
  # creates foreign key constraints for columns whose names end in
  # <tt>_id</tt>.  So the above examples are redundant, unless automatic
  # creation was disabled at initialization in the global Config.
  #
  # SchemaPlus likewise by default automatically creates foreign key constraints for
  # columns defined via <tt>t.references</tt>.   However, SchemaPlus does not create
  # foreign key constraints if the <tt>:polymorphic</tt> option is true
  #
  # Finally, the configuration for foreign keys can be overriden on a per-table
  # basis by passing Config options to Migration::ClassMethods#create_table, such as
  #
  #      create_table :students, :foreign_keys => {:auto_create => false} do
  #         t.integer :student_id
  #      end
  #
  module TableDefinition
    include SchemaPlus::ActiveRecord::ColumnOptionsHandler

    attr_accessor :schema_plus_config #:nodoc:

    def self.included(base) #:nodoc:
      base.class_eval do
        attr_accessor :name
        attr_accessor :indexes
        alias_method_chain :initialize, :schema_plus
        alias_method_chain :column, :schema_plus
        alias_method_chain :references, :schema_plus
        alias_method_chain :belongs_to, :schema_plus
        alias_method_chain :primary_key, :schema_plus
        alias_method_chain :to_sql, :schema_plus
      end
    end
        
    def initialize_with_schema_plus(*args) #:nodoc:
      initialize_without_schema_plus(*args)
      @foreign_keys = []
      @indexes = []
    end

    def primary_key_with_schema_plus(name, options = {}) #:nodoc:
      column(name, :primary_key, options)
    end

    # need detect :polymorphic at this level, because rails strips it out
    # before calling #column (twice, once for _id and once for _type)
    def references_with_schema_plus(*args) #:nodoc:
      options = args.extract_options!
      options[:references] = nil if options[:polymorphic]
      args << options
      references_without_schema_plus(*args)
    end

    # need detect :polymorphic at this level, because rails strips it out
    # before calling #column (twice, once for _id and once for _type)
    def belongs_to_with_schema_plus(*args) #:nodoc:
      options = args.extract_options!
      options[:references] = nil if options[:polymorphic]
      args << options
      belongs_to_without_schema_plus(*args)
    end

    def column_with_schema_plus(name, type, options = {}) #:nodoc:
      column_without_schema_plus(name, type, options)
      schema_plus_handle_column_options(self.name, name, options, :config => schema_plus_config)
      self
    end

    def to_sql_with_schema_plus #:nodoc:
      sql = to_sql_without_schema_plus
      sql << ', ' << @foreign_keys.map(&:to_sql) * ', ' unless @foreign_keys.empty?
      sql
    end

    # Define an index for the current 
    def index(column_name, options={})
      @indexes << ::ActiveRecord::ConnectionAdapters::IndexDefinition.new(self.name, column_name, options)
    end

    def foreign_key(column_names, references_table_name, references_column_names, options = {})
      @foreign_keys << ForeignKeyDefinition.new(options[:name], nil, column_names, ::ActiveRecord::Migrator.proper_table_name(references_table_name), references_column_names, options[:on_update], options[:on_delete], options[:deferrable])
      self
    end

    protected
    # The only purpose of that method is to provide a consistent intefrace
    # for ColumnOptionsHandler. First argument (table name) is ignored.
    def add_index(_, *args) #:nodoc:
      index(*args)
    end

    # The only purpose of that method is to provide a consistent intefrace
    # for ColumnOptionsHandler. First argument (table name) is ignored.
    def add_foreign_key(_, *args) #:nodoc:
      foreign_key(*args)
    end

  end
end
