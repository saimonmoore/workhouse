# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'work_house/version'

Gem::Specification.new do |spec|
  spec.name          = "work_house"
  spec.version       = WorkHouse::VERSION
  spec.authors       = ["Saimon Moore"]
  spec.email         = ["saimonmoore@gmail.com"]
  spec.description   = %q{Run certain jobs periodically}
  spec.summary       = %q{WorkHouse is an in-memory periodical job handler}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 3.2"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 2.14"
end
