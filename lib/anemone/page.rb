require 'nokogiri'
require 'ostruct'

module Anemone
  class Page

    # The URL of the page
    attr_reader :url
    # Headers of the HTTP response
    attr_reader :headers

    # OpenStruct for user-stored data
    attr_accessor :data
    # Nokogiri document for the HTML body
    attr_accessor :doc
    # Integer response code of the page
    attr_accessor :code
    # Array of redirect-aliases for the page
    attr_accessor :aliases
    # Boolean indicating whether or not this page has been visited in PageStore#shortest_paths!
    attr_accessor :visited
    # Depth of this page from the root of the crawl. This is not necessarily the
    # shortest path; use PageStore#shortest_paths! to find that value.
    attr_accessor :depth
    # URL of the page that brought us to this page
    attr_accessor :referer
    # Response time of the request for this page in milliseconds
    attr_accessor :response_time

    #
    # Create a new page
    #
    def initialize(url, body = nil, code = nil, headers = nil, aka = nil, referer = nil, depth = 0, response_time = nil)
      @url = url
      @code = code
      @headers = headers || {}
      @headers['content-type'] ||= ['']
      @aliases = Array(aka)
      @data = OpenStruct.new
      @referer = referer
      @depth = depth || 0
      @response_time = response_time
      @doc = Nokogiri::HTML(body) if body && html? rescue nil
    end

    # Array of distinct A tag HREFs from the page
    def links
      return @links unless @links.nil?
      @links = []
      return @links if !doc

      doc.css('a').each do |a|
        u = a.attributes['href'].content rescue nil
        next if u.nil? or u.empty?
        abs = to_absolute(URI(u)) rescue next
        @links << abs if in_domain?(abs)
      end
      @links.uniq!
      @links
    end

    def discard_doc!
      links # force parsing of page links before we trash the document
      @doc = nil
    end

    #
    # Return a new page with the same *response* and *url*, but
    # with a 200 response code
    #
    def alias_clone(url)
      p = clone
	  p.add_alias!(@aka) if !@aka.nil?
	  p.code = 200
	  p
    end

    #
    # Add a redirect-alias String *aka* to the list of the page's aliases
    #
    # Returns *self*
    #
    def add_alias!(aka)
      @aliases << aka if !@aliases.include?(aka)
      self
    end

    #
    # Returns an Array of all links from this page, and all the
    # redirect-aliases of those pages, as String objects.
    #
    # *page_hash* is a PageStore object with the results of the current crawl.
    #
    def links_and_their_aliases(page_hash)
      links.inject([]) do |results, link|
        results.concat([link].concat(page_hash[link].aliases))
      end
    end

    #
    # The content-type returned by the HTTP request for this page
    #
    def content_type
      headers['content-type'].first
    end

    #
    # Returns +true+ if the page is a HTML document, returns +false+
    # otherwise.
    #
    def html?
      !!(content_type =~ %r{^(text/html|application/xhtml+xml)\b})
    end

    #
    # Returns +true+ if the page is a HTTP redirect, returns +false+
    # otherwise.
    #
    def redirect?
      (300..399).include?(@code)
    end

    #
    # Returns +true+ if the page was not found (returned 404 code),
    # returns +false+ otherwise.
    #
    def not_found?
      404 == @code
    end

    #
    # Converts relative URL *link* into an absolute URL based on the
    # location of the page
    #
    def to_absolute(link)
      # remove anchor
      link = URI.encode(link.to_s.gsub(/#[a-zA-Z0-9_-]*$/,''))

      relative = URI(link)
      absolute = @url.merge(relative)

      absolute.path = '/' if absolute.path.empty?

      return absolute
    end

    #
    # Returns +true+ if *uri* is in the same domain as the page, returns
    # +false+ otherwise
    #
    def in_domain?(uri)
      uri.host == @url.host
    end
  end
end
