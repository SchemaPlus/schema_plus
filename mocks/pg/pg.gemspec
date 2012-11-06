# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "pg"
  s.version     = "0.99"
  s.platform    = Gem::Platform::RUBY

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

end


