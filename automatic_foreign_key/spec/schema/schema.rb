ActiveRecord::Schema.define do

  create_table :users, :force => true do |t|
    t.string :login
  end
  add_index :users, :login, :unique => true

  create_table :members, :force => true do |t|
    t.string :login
  end
  
  create_table :comments, :force => true do |t|
    t.string :content
    t.integer :user
    t.integer :user_id
  end

  add_foreign_key :comments, :user_id, :users, :id

  create_table :posts, :force => true do |t|
    t.string :content
  end

end
