ActiveSchema.setup do |config|

  # Migration will generate foreign key if column name has _id suffix.
  # config.foreign_keys.auto_create = true
  #
  # Examples:
  #
  # when a column is added foreign_key will be generated automagically
  # add_column :posts, :user_id # adds FK to users(id)
  #
  # create_table :comments do |t|
  #   t.integer :post_id # adds FK to posts(id)
  # end
  #
  # force author_id to reference users table
  # t.integer :author_id, :references => :users
  #
  # prevent foreign key from being created
  # t.string :session_id, :references => nil
  #
  # Default ON UPDATE action
  # Available values are :cascade, :restrict, :set_null, :set_default, :no_action
  # config.foreign_keys.on_update = :cascade
  #
  # Default ON DELETE action
  # Available values are :cascade, :restrict, :set_null, :set_default, :no_action
  # config.foreign_keys.on_delete = :restrict
  #
  # Create an index on foreign key column.
  # It's relevant for PostgreSQL and SQLite only.
  # MySQL engines auto-index foreign keys by default
  # config.foreign_keys.auto_index = true

end
