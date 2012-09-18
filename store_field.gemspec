# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'store_field/version'

Gem::Specification.new do |gem|
  gem.name          = 'store_field'
  gem.version       = StoreField::VERSION
  gem.authors       = ['Kenn Ejima']
  gem.email         = ['kenn.ejima@gmail.com']
  gem.description   = %q{Nested fields for ActiveRecord::Store}
  gem.summary       = %q{Nested fields for ActiveRecord::Store}
  gem.homepage      = 'https://github.com/kenn/store_field'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'activerecord', '>= 3.2.0'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'sqlite3'
end
