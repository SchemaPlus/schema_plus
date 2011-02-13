ActiveRecord::Schema.define do
  connection.tables.each do |table| drop_table table end

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

  create_table :posts, :force => true do |t|
    t.string :content
  end

end
