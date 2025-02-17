require_relative './lib/temporal/version'

Gem::Specification.new do |spec|
  spec.name          = 'temporal-ruby'
  spec.version       = Temporal::VERSION
  spec.authors       = ['Anthony Dmitriyev']
  spec.email         = ['anthony.dmitriyev@coinbase.com']

  spec.summary       = 'Temporal Ruby client'
  spec.description   = 'A Ruby client for implementing Temporal workflows and activities in Ruby'
  spec.homepage      = 'https://github.com/coinbase/temporal-ruby'
  spec.license       = 'Apache-2.0'

  spec.require_paths = ['lib']
  spec.files         = Dir["{lib,rbi}/**/*.*"] + %w(temporal.gemspec Gemfile LICENSE README.md)

  spec.add_dependency 'grpc'
  spec.add_dependency 'oj'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'fabrication'
  spec.add_development_dependency 'grpc-tools'
  spec.add_development_dependency 'yard'
end
