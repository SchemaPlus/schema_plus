ActiveRecord::Schema.define do

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
  end

  add_foreign_key :comments, :post_id, :posts, :id

end
