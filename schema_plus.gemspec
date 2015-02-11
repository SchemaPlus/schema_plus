# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "schema_plus/version"

Gem::Specification.new do |gem|
  gem.name        = "schema_plus"
  gem.version     = SchemaPlus::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.required_ruby_version = ">= 1.9.2"
  gem.authors     = ["Ronen Barzel", "Michal Lomnicki"]
  gem.email       = ["ronen@barzel.org", "michal.lomnicki@gmail.com"]
  gem.homepage    = "https://github.com/SchemaPlus/schema_plus"
  gem.summary     = "Enhances ActiveRecord schema mechanism, including more DRY index creation and support for foreign key constraints and views."
  gem.description = "SchemaPlus is an ActiveRecord extension that provides enhanced capabilities for schema definition and querying, including: enhanced and more DRY index capabilities, support and automation for foreign key constraints, and support for views."
  gem.license = 'MIT'

  gem.rubyforge_project = "schema_plus"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_dependency "activerecord", "~> 4.2"
  gem.add_dependency "valuable"
  gem.add_dependency "schema_plus_core", "~> 0.1"
  gem.add_dependency "schema_monkey_rails", "~> 0.1", ">= 0.1.2"
  gem.add_dependency "schema_plus_indexes", "~> 0.1", ">= 0.1.3"
  gem.add_dependency "schema_plus_pg_indexes", "~> 0.1", ">= 0.1.3"
  gem.add_dependency "schema_plus_views", "~> 0.1"

  gem.add_development_dependency "schema_dev", "~> 3.1"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 3.0"
  gem.add_development_dependency "rdoc"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "simplecov-gem-profile"
end

