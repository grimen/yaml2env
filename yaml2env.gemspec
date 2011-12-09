# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "yaml2env/version"

Gem::Specification.new do |s|
  s.name        = "yaml2env"
  s.version     = Yaml2env::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Merchii", "Jonas Grimfelt"]
  s.email       = ["jonas@merchii.com", "grimen@gmail.com"]
  s.homepage    = "http://github.com/merchii/yaml2env"
  s.summary     = %q{YAML => ENV for environment-specific configs}
  s.description = %q{Stash environment-specific configs in YAML-files and load them into ENV according to best-practices pattern - and auto-detects on-initialization if something is missing (skipping the "scratching the head"-part).}

  s.add_development_dependency 'rake'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-bundler'
  s.add_development_dependency 'guard-minitest'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
