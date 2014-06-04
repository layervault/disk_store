# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'disk_store/version'

Gem::Specification.new do |gem|
  gem.name          = "disk_store"
  gem.version       = DiskStore::VERSION
  gem.authors       = ["Kelly Sutton"]
  gem.email         = ["kelly@layervault.com"]
  gem.description   = %q{Cache files the smart way.}
  gem.summary       = %q{Cache fiels the smart way.}
  gem.homepage      = "http://cosmos.layervault.com/cache.html"
  gem.license       = 'MIT'
  gem.required_ruby_version = ">= 2.0.0"

  gem.files         = `git ls-files`.split($/).delete_if { |f| f.include?('examples/') }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "rake"
  gem.add_dependency "celluloid"

  gem.test_files = Dir.glob("spec/**/*")
  gem.add_development_dependency "rspec"
end
