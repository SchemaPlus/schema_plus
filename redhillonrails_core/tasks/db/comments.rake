namespace :db do
  desc "Describe all the tables in the database by reading the table comments"
  task :comments => :environment do
    ActiveRecord::Base.connection.tables.sort.each do |table_name|
      comment = ActiveRecord::Base.connection.table_comment(table_name)
      puts "#{table_name} - #{comment}"
    end
  end
end
