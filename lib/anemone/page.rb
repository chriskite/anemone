require 'anemone/http'
require 'nokogiri'
require 'facets/ostructable'

module Anemone
  class Page
    include OpenStructable

    # The URL of the page
    attr_reader :url
    # Array of distinct A tag HREFs from the page
    attr_reader :links
    #Content-type of the  HTTP response
    attr_reader :content_type
    
    #Nokogiri document for the HTML body
    attr_accessor :doc
    # Integer response code of the page
    attr_accessor :code	
    # Array of redirect-aliases for the page
    attr_accessor :aliases
    # Boolean indicating whether or not this page has been visited in PageHash#shortest_paths!
    attr_accessor :visited
    # Used by PageHash#shortest_paths! to store depth of the page
    attr_accessor :depth
    
    #
    # Create a new Page from the response of an HTTP request to *url*
    #
    def self.fetch(url)
      begin
        url = URI(url) if url.is_a?(String)

        response, code, location = Anemone::HTTP.get(url)

        aka = nil
        if !url.eql?(location)
          aka = location
        end

        return Page.new(url, response.body, code, response['Content-Type'], aka)
      rescue
        return Page.new(url)
      end
    end
    
    #
    # Create a new page
    #
    def initialize(url, body = nil, code = nil, content_type = nil, aka = nil)
      @url = url
      @code = code
      @content_type = content_type
      @links = []
      @aliases = []
	  
      #create empty storage for OpenStructable
      update({})
	  
      @aliases << aka if !aka.nil?

      if body
        begin
          @doc = Nokogiri::HTML(body)
        rescue
          return
        end

        return if @doc.nil?

        #get a list of distinct links on the page, in absolute url form
        @doc.css('a').each do |a| 
          u = a.attributes['href'].content if a.attributes['href']
          next if u.nil?
          
          begin
            abs = to_absolute(URI(u))
          rescue
            next
          end

          @links << abs if in_domain?(abs)
        end
        
        @links.uniq!
      end
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
    # *page_hash* is a PageHash object with the results of the current crawl.
    #
    def links_and_their_aliases(page_hash)
      @links.inject([]) do |results, link|
        results.concat([link].concat(page_hash[link].aliases))
      end
    end
    
    #
    # Returns +true+ if the page is a HTML document, returns +false+
    # otherwise.
    #
    def html?
      (@content_type =~ /text\/html/) == 0
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
