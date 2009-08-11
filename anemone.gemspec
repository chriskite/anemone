spec = Gem::Specification.new do |s| 
  s.name = "anemone"
  s.version = "0.1.2"
  s.author = "Chris Kite"
  s.homepage = "http://anemone.rubyforge.org"
  s.rubyforge_project = "anemone"
  s.platform = Gem::Platform::RUBY
  s.summary = "Anemone web-spider framework"
  s.executables = %w[anemone_count.rb anemone_cron.rb anemone_pagedepth.rb anemone_serialize.rb anemone_url_list.rb]
  s.require_path = "lib"
  s.has_rdoc = true
  s.rdoc_options << '-m' << 'README.rdoc' << '-t' << 'Anemone'
  s.extra_rdoc_files = ["README.rdoc"]
  s.add_dependency("nokogiri", ">= 1.3.0")
  
  s.files = %w[
    LICENSE.txt
    README.rdoc
    bin/anemone_count.rb
    bin/anemone_cron.rb
    bin/anemone_pagedepth.rb
    bin/anemone_serialize.rb
    bin/anemone_url_list.rb
    lib/anemone.rb
    lib/anemone/anemone.rb
    lib/anemone/core.rb
    lib/anemone/http.rb
    lib/anemone/page.rb
    lib/anemone/page_hash.rb
    lib/anemone/tentacle.rb
  ]
  
  s.test_files = %w[
    spec/anemone_spec.rb
    spec/core_spec.rb
    spec/page_spec.rb
    spec/fakeweb_helper.rb
    spec/spec_helper.rb
  ]
end
