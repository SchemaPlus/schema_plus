source :rubygems

gem "pg"
gem "activerecord", "< 3.0.0"
gem "rake"

group :development, :test do
  gem "jeweler"
  gem "micronaut"

  platforms :ruby_18 do
    gem "ruby-debug"
  end

  platforms :ruby_19 do
    gem "ruby-debug19"
  end
end

# vim: ft=ruby
