require 'net/https'
require 'anemone/page'

module Anemone
  class HTTP
    # Maximum number of redirects to follow on each get_response
    REDIRECTION_LIMIT = 5

    def initialize
      @connections = {}
    end

    #
    # Create a new Page from the response of an HTTP request to *url*
    #
    def fetch_page(url, from_page = nil)
      begin
        url = URI(url) unless url.is_a?(URI)

        if from_page
          referer = from_page.url
          depth = from_page.depth + 1
        end

        response, code, location, response_time = get(url, referer)

        aka = nil
        if !url.eql?(location)
          aka = location
        end

        return Page.new(url, response.body, code, response.to_hash, aka, referer, depth, response_time)
      rescue
        return Page.new(url)
      end
    end

    private

    #
    # Retrieve an HTTP response for *url*, following redirects.
    # Returns the response object, response code, and final URI location.
    # 
    def get(url, referer = nil)
      response, response_time = get_response(url, referer)
      code = Integer(response.code)
      loc = url
      
      limit = REDIRECTION_LIMIT
      while response.is_a?(Net::HTTPRedirection) and limit > 0
          loc = URI(response['location'])
          loc = url.merge(loc) if loc.relative?
          response, response_time = get_response(loc, referer)
          limit -= 1
      end

      return response, code, loc, response_time
    end
    
    #
    # Get an HTTPResponse for *url*, sending the appropriate User-Agent string
    #
    def get_response(url, referer = nil)
      full_path = url.query.nil? ? url.path : "#{url.path}?#{url.query}"
      user_agent = Anemone.options.user_agent rescue nil
      
      opts = {}
      opts['User-Agent'] = user_agent if user_agent
      opts['Referer'] = referer.to_s if referer

      retries = 0
      begin
        start = Time.now()
        response = connection(url).get(full_path, opts)
        finish = Time.now()
        response_time = ((finish - start) * 1000).round
        return response, response_time 
      rescue EOFError
        refresh_connection(url)
        retries += 1
        retry unless retries > 1
      end
    end

    def connection(url)
      @connections[url.host] ||= {}

      if conn = @connections[url.host][url.port]
        return conn
      end

      refresh_connection(url)
    end

    def refresh_connection(url)
      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      @connections[url.host][url.port] = http.start      
    end
  end
end
