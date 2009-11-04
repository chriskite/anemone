require 'net/https'
require 'anemone/page'

module Anemone
  class HTTP
    # Maximum number of redirects to follow on each get_response
    REDIRECT_LIMIT = 5

    def initialize(opts = {})
      @connections = {}
      @opts = opts
    end

    #
    # Fetch a single Page from the response of an HTTP request to *url*.
    # Just gets the final destination page.
    #
    def fetch_page(url, referer = nil, depth = nil)
      fetch_pages(url, referer, depth).last
    end

    #
    # Create new Pages from the response of an HTTP request to *url*,
    # including redirects
    #
    def fetch_pages(url, referer = nil, depth = nil)
      begin
        url = URI(url) unless url.is_a?(URI)
        pages = []
        get(url, referer) do |response, code, location, redirect_to, response_time|
          pages << Page.new(location, :body => response.body.dup,
                                      :code => code,
                                      :headers => response.to_hash,
                                      :referer => referer,
                                      :depth => depth,
                                      :redirect_to => redirect_to,
                                      :response_time => response_time)
        end

        return pages
      rescue => e
        if verbose?
          puts e.inspect
          puts e.backtrace
        end
        return [Page.new(url, :error => e)]
      end
    end

    private

    #
    # Retrieve HTTP responses for *url*, including redirects.
    # Yields the response object, response code, and URI location
    # for each response.
    #
    def get(url, referer = nil)
      response, response_time = get_response(url, referer)
      code = Integer(response.code)
      loc = url
      redirect_to = response.is_a?(Net::HTTPRedirection) ?  URI(response['location']) : nil
      yield response, code, loc, redirect_to, response_time

      limit = redirect_limit
      while response.is_a?(Net::HTTPRedirection) and limit > 0
          loc = redirect_to
          loc = url.merge(loc) if loc.relative?
          response, response_time = get_response(loc, referer)
          code = Integer(response.code)
          redirect_to = response.is_a?(Net::HTTPRedirection) ?  URI(response['location']) : nil
          yield response, code, loc, redirect_to, response_time
          limit -= 1
      end
    end

    #
    # Get an HTTPResponse for *url*, sending the appropriate User-Agent string
    #
    def get_response(url, referer = nil)
      full_path = url.query.nil? ? url.path : "#{url.path}?#{url.query}"

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
        retry unless retries > 3
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

    def redirect_limit
      @opts[:redirect_limit] || REDIRECT_LIMIT
    end

    def user_agent
      @opts[:user_agent]
    end

    def verbose?
      @opts[:verbose]
    end

  end
end
