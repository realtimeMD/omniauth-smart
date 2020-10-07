# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "omniauth-smart/version"

Gem::Specification.new do |gem|
  gem.add_runtime_dependency "omniauth", "~> 1.0"
  gem.add_runtime_dependency "jwt", "~> 2.2.1"
  gem.add_runtime_dependency "faraday", ">= 0.8"
  gem.add_runtime_dependency "multi_json", "~> 1.3"

  gem.add_development_dependency "bundler", "~> 1.14"
  gem.add_development_dependency "rake", "~> 13.0"
  gem.add_development_dependency "rack-test", "~> 1.1"
  gem.add_development_dependency "rspec", "~> 3.6"
  gem.add_development_dependency "webmock", "~> 3.0"
  gem.add_development_dependency "sinatra", "~> 2"
  gem.add_development_dependency "rubocop", "~> 0.75.1"
  gem.add_development_dependency "rubocop-rails_config", "0.7.3"
  gem.add_development_dependency "rubocop-performance", "~> 1.5.0"
  gem.add_development_dependency "bundler-audit", "~> 0.6.0"
  gem.add_development_dependency "byebug"

  gem.name          = "omniauth-smart"
  gem.version       = OmniAuth::Smart::VERSION
  gem.authors       = ["Enigneers at ACT.md"]
  gem.email         = ["engineering@act.md"]

  gem.summary       = "SMART authentication strategy see https://smarthealthit.org"
  gem.description   = gem.summary
  gem.homepage      = "http://github.com/actmd/omniauth-smart"
  gem.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if gem.respond_to?(:metadata)
    gem.metadata["allowed_push_host"] = "http://github.com/actmd/omniauth-smart"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  gem.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(spec|test|gem|features)/})
  end
  gem.bindir        = "exe"
  gem.executables   = gem.files.grep(%r{^exe/}) { |f| File.basename(f) }
  gem.require_paths = ["lib"]
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
end
