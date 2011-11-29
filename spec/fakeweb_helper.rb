FakeWeb.allow_net_connect = false

module Anemone
  SPEC_DOMAIN = "http://www.example.com/"
  AUTH_SPEC_DOMAIN = "http://user:pass@#{URI.parse(SPEC_DOMAIN).host}/"

  class FakePage
    attr_accessor :links
    attr_accessor :hrefs
    attr_accessor :body

    def initialize(name = '', options = {})
      @name = name
      @links = [options[:links]].flatten if options.has_key?(:links)
      @hrefs = [options[:hrefs]].flatten if options.has_key?(:hrefs)
      @redirect = options[:redirect] if options.has_key?(:redirect)
      @auth = options[:auth] if options.has_key?(:auth)
      @base = options[:base] if options.has_key?(:base)      
      @content_type = options[:content_type] || "text/html"
      @body = options[:body]

      create_body unless @body
      add_to_fakeweb
    end

    def url
      SPEC_DOMAIN + @name
    end

    def auth_url
      AUTH_SPEC_DOMAIN + @name
    end

    private

    def create_body
      if @base
        @body = "<html><head><base href=\"#{@base}\"></head><body>"
      else
        @body = "<html><body>"
      end
      @links.each{|l| @body += "<a href=\"#{SPEC_DOMAIN}#{l}\"></a>"} if @links
      @hrefs.each{|h| @body += "<a href=\"#{h}\"></a>"} if @hrefs
      @body += "</body></html>"
    end

    def add_to_fakeweb
      options = {:body => @body, :content_type => @content_type, :status => [200, "OK"]}

      if @redirect
        options[:status] = [301, "Permanently Moved"]

        # only prepend SPEC_DOMAIN if a relative url (without an http scheme) was specified
        redirect_url = (@redirect =~ /http/) ? @redirect : SPEC_DOMAIN + @redirect
        options[:location] = redirect_url

        # register the page this one redirects to
        FakeWeb.register_uri(:get, redirect_url, {:body => '',
                                                  :content_type => @content_type,
                                                  :status => [200, "OK"]})
      end

      if @auth
        unautorized_options = {
          :body => "Unauthorized", :status => ["401", "Unauthorized"]
        }
        FakeWeb.register_uri(:get, SPEC_DOMAIN + @name, unautorized_options)
        FakeWeb.register_uri(:get, AUTH_SPEC_DOMAIN + @name, options)
      else
        FakeWeb.register_uri(:get, SPEC_DOMAIN + @name, options)
      end
    end
  end
end

#default root
Anemone::FakePage.new
