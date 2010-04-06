ActiveRecord::Schema.define do

  create_table :users, :force => true do |t|
    t.string :login
  end
  add_index :users, :login, :unique => true
  
  create_table :comments, :force => true do |t|
    t.string :content
  end

  create_table :posts, :force => true do |t|
    t.string :content
  end

end
