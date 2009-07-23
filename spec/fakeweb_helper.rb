begin
  require 'fakeweb'
rescue LoadError
  warn "You need the 'fakeweb' gem installed to test Anemone"
  exit
end

FakeWeb.allow_net_connect = false

module Anemone
  SPEC_DOMAIN = "http://www.example.com/"
  
  class FakePage
    attr_accessor :links
    attr_accessor :hrefs
    
    def initialize(name = '', options = {})
      @name = name
      @links = [options[:links]].flatten if options.has_key?(:links)
      @hrefs = [options[:hrefs]].flatten if options.has_key?(:hrefs)
      @redirect = options[:redirect] if options.has_key?(:redirect)
      
      create_body
      add_to_fakeweb
    end
    
    def url
      SPEC_DOMAIN + @name
    end
    
    private
    
    def create_body
      @body = "<html><body>"
      @links.each{|l| @body += "<a href=\"#{SPEC_DOMAIN}#{l}\"></a>"} if @links
      @hrefs.each{|h| @body += "<a href=\"#{h}\"></a>"} if @hrefs
      @body += "</body></html>"
    end
    
    def add_to_fakeweb
      options = {:body => @body, :content_type => "text/html", :status => [200, "OK"]}
      
      if @redirect
        options[:status] = [301, "Permanently Moved"] 
        options[:location] = SPEC_DOMAIN + @redirect
      end

      FakeWeb.register_uri(:get, SPEC_DOMAIN + @name, options)
    end
  end
end

#default root
Anemone::FakePage.new

