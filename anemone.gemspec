spec = Gem::Specification.new do |s| 
  s.name = "anemone"
  s.version = "0.0.5"
  s.author = "Chris Kite"
  s.homepage = "http://anemone.rubyforge.org"
  s.rubyforge_project = "anemone"
  s.platform = Gem::Platform::RUBY
  s.summary = "Anemone web-spider framework"
  s.files = Dir["{bin,lib}/**/*"] + Dir["README.rdoc"]
  s.executables = %w[anemone_count.rb anemone_cron.rb anemone_pagedepth.rb anemone_serialize.rb anemone_url_list.rb]
  s.require_path = "lib"
  s.has_rdoc = true
  s.rdoc_options << '-m' << 'README.rdoc' << '-t' << 'Anemone'
  s.extra_rdoc_files = ["README.rdoc"]
  s.add_dependency("nokogiri", ">= 1.3.0")
  s.add_dependency("facets", ">= 2.5.0")
end
