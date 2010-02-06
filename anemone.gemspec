spec = Gem::Specification.new do |s|
  s.name = "anemone"
  s.version = "0.3.2"
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
  s.add_dependency("robots", ">= 0.7.2")

  s.files = %w[
    LICENSE.txt
    CHANGELOG.rdoc
    README.rdoc
    bin/anemone
    lib/anemone.rb
    lib/anemone/cookie_store.rb
    lib/anemone/core.rb
    lib/anemone/http.rb
    lib/anemone/page.rb
    lib/anemone/page_store.rb
    lib/anemone/tentacle.rb
    lib/anemone/storage.rb
    lib/anemone/storage/pstore.rb
    lib/anemone/storage/tokyo_cabinet.rb
    lib/anemone/cli.rb
    lib/anemone/cli/url_list.rb
    lib/anemone/cli/cron.rb
    lib/anemone/cli/count.rb
    lib/anemone/cli/pagedepth.rb
    lib/anemone/cli/serialize.rb
  ]

  s.test_files = %w[
    spec/anemone_spec.rb
    spec/core_spec.rb
    spec/page_spec.rb
    spec/page_store_spec.rb
    spec/http_spec.rb
    spec/storage_spec.rb
    spec/fakeweb_helper.rb
    spec/spec_helper.rb
  ]
end
