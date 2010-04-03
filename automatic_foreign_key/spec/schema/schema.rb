ActiveRecord::Schema.define do
  
  create_table :comments, :force => true do |t|
    t.content :string
  end

  create_table :posts, :force => true do |t|
    t.content :text
  end

end
