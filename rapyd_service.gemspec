# frozen_string_literal: true

require_relative 'lib/rapyd_service/version'

Gem::Specification.new do |spec|
  spec.name          = 'rapyd_service'
  spec.version       = RapydService::VERSION
  spec.authors       = ['furqan-cn']
  spec.email         = ['furqan@weareavp.com']

  spec.summary       = 'Rapyd payment services gem.'
  spec.homepage      = 'https://github.com/furqan-cn/artwallst-local.git'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = 'https://rubygems.org/gems/rapyd_service'
  spec.metadata['source_code_uri'] = 'https://github.com/furqan-cn/artwallst-local.git'
  spec.metadata['changelog_uri'] = 'https://github.com/furqan-cn/artwallst-local.git'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir['{bin,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md', 'Gemfile.lock', 'Gemfile']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'bundler'
  spec.add_dependency 'rake', '~> 13.0.3'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'rspec', '~> 3.4.0'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
