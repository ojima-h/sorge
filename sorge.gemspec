# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sorge/version'

Gem::Specification.new do |spec|
  spec.name          = 'sorge'
  spec.version       = Sorge::VERSION
  spec.authors       = ['Hikaru Ojima']
  spec.email         = ['amijo4rihaku@gmail.com']

  spec.summary       = 'Sorge is a simple Workflow Engine for mini-batch.'
  spec.description   = 'Sorge is a simple Workflow Engine for mini-batch.'
  spec.homepage      = 'https://github.com/ojima-h/sorge'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|sample)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'yard'

  spec.add_dependency 'rake'
  spec.add_dependency 'concurrent-ruby-ext'
  spec.add_dependency 'sequel'
  spec.add_dependency 'sqlite3'
  spec.add_dependency 'thor'
end
