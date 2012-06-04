# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "schema_plus/version"

Gem::Specification.new do |s|
  s.name        = "schema_plus"
  s.version     = SchemaPlus::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ronen Barzel", "Michal Lomnicki"]
  s.email       = ["ronen@barzel.org", "michal.lomnicki@gmail.com"]
  s.homepage    = "https://github.com/lomba/schema_plus"
  s.summary     = "Enhances ActiveRecord schema mechanism, including more DRY index creation and support for foreign key constraints and views."
  s.description = "SchemaPlus is an ActiveRecord extension that provides enhanced capabilities for schema definition and querying, including: enhanced and more DRY index capabilities, support and automation for foreign key constraints, and support for views."


  s.rubyforge_project = "schema_plus"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("rails")
  s.add_dependency("valuable")

  s.add_development_dependency("rake")
  s.add_development_dependency("rspec")
  s.add_development_dependency("pg")
  s.add_development_dependency("mysql")
  s.add_development_dependency("sqlite3")
  s.add_development_dependency("simplecov")
  s.add_development_dependency("simplecov-gem-adapter")
end

