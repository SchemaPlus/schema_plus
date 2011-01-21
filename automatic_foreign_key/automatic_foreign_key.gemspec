# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "automatic_foreign_key/version"

Gem::Specification.new do |s|
  s.name        = "automatic_foreign_key"
  s.version     = AutomaticForeignKey::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Michał Łomnicki"]
  s.email       = ["michal.lomnicki@gmail.com"]
  s.homepage    = "https://github.com/mlomnicki/automatic_foreign_key"
  s.summary     = "Automatically generate foreign-key constraints when creating tables"
  s.description = "Automatic Foreign Key automatically generates foreign-key \
constraints when creating tables or adding columns. It uses SQL-92 syntax and as such should be compatible with most databases that support foreign-key constraints."

  s.rubyforge_project = "automatic_foreign_key"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("activerecord", ">= 2")
  s.add_dependency("redhillonrails_core", "~> 1.1.2")
      
  s.add_development_dependency("rspec", "~> 2.4.0")
  s.add_development_dependency("pg")
  s.add_development_dependency("mysql")
  s.add_development_dependency("mysql2")
  s.add_development_dependency("sqlite3")
end

