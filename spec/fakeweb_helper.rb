require 'fakeweb'

FakeWeb.register_uri(:get, "http://example.com/", :body => "Hello World!")

