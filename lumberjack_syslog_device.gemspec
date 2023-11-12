Gem::Specification.new do |spec|
  spec.name = 'lumberjack_syslog_device'
  spec.version = File.read(File.expand_path("../VERSION", __FILE__)).strip
  spec.authors = ['Brian Durand']
  spec.email = ['bbdurand@gmail.com']

  spec.summary = "A logging device for the lumberjack gem that writes log entries to syslog."
  spec.homepage = "https://github.com/bdurand/lumberjack_syslog_device"
  spec.license = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  ignore_files = %w(
    .gitignore
    .travis.yml
    Appraisals
    Gemfile
    Gemfile.lock
    Rakefile
    gemfiles/
    spec/
  )
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject{ |f| ignore_files.any?{ |path| f.start_with?(path) } }
  end

  spec.require_paths = ['lib']

  spec.required_ruby_version = '>=2.4'

  spec.add_dependency "lumberjack", ">=1.1"

  spec.add_development_dependency "bundler"
end
