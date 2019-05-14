# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'xcactivitylog'
  spec.version       = File.read(File.expand_path('VERSION', __dir__)).chomp
  spec.authors       = ['Samuel Giddins']
  spec.email         = ['segiddins@segiddins.me']

  spec.summary       = "Parse Xcode's xcactivitylog files (and other SLF0-serialized files)"
  spec.homepage      = 'https://github.com/segiddins/xcactivitylog'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir['*.{md,txt}', 'VERSION', 'lib/{**/,}*.rb', 'exe/*', base: __dir__]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
