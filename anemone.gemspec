spec = Gem::Specification.new do |s|
  s.name = "anemone"
  s.version = "0.7.2"
  s.author = "Chris Kite"
  s.homepage = "http://anemone.rubyforge.org"
  s.rubyforge_project = "anemone"
  s.platform = Gem::Platform::RUBY
  s.summary = "Anemone web-spider framework"
  s.executables = %w[anemone]
  s.require_path = "lib"
  s.has_rdoc = true
  s.rdoc_options << '-m' << 'README.rdoc' << '-t' << 'Anemone'
  s.extra_rdoc_files = ["README.rdoc"]
  s.add_dependency("nokogiri", ">= 1.3.0")
  s.add_dependency("robotex", ">= 1.0.0")

  s.add_development_dependency "rake", ">=0.9.2"
  s.add_development_dependency "rdoc", ">=3.12"
  s.add_development_dependency "rspec", ">=2.8.0"
  s.add_development_dependency "fakeweb", ">=1.3.0"
  s.add_development_dependency "redis", ">=2.2.0"
  s.add_development_dependency "mongo", ">=1.3.1"
  s.add_development_dependency "bson_ext", ">=1.3.1"
  s.add_development_dependency "tokyocabinet", ">=1.29"
  s.add_development_dependency "kyotocabinet-ruby", ">=1.27.1"
  s.add_development_dependency "sqlite3", ">=1.3.4"

  s.files = %w[
    VERSION
    LICENSE.txt
    CHANGELOG.rdoc
    README.rdoc
    Rakefile
  ] + Dir['lib/**/*.rb']

  s.test_files = Dir['spec/*.rb']
end
