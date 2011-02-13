ActiveRecord::Schema.define do
  connection.tables.each do |table| drop_table table end

  create_table :users, :force => true do |t|
    t.string :login
    t.datetime :deleted_at
  end

  create_table :posts, :force => true do |t|
    t.text :body
    t.integer :user_id
    t.integer :author_id
  end

  create_table :comments, :force => true do |t|
    t.text :body
    t.integer :post_id
    t.foreign_key :post_id, :posts, :id
  end

end
