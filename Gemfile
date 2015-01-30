source "http://rubygems.org"

gemspec

File.exist?(gemfile_local = File.expand_path('../Gemfile.local', __FILE__)) and eval File.read(gemfile_local), binding, gemfile_local
