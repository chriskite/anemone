require 'anemone/page'
require 'anemone/cookie_store'

module Anemone
  class HTTP
    # Maximum number of redirects to follow on each get_response
    REDIRECT_LIMIT = 5

    # CookieStore for this HTTP client
    attr_reader :cookie_store

    def initialize(opts = {})
      @opts = opts
      @cookie_store = CookieStore.new(@opts[:cookies])
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
        get(url, referer) do |response, headers, code, location, redirect_to, response_time|
          pages << Page.new(location, :body => response,
                                      :headers => headers,
                                      :code => code,
                                      :referer => referer,
                                      :depth => depth,
                                      :redirect_to => redirect_to,
                                      :response_time => response_time)
        end

        return pages
      rescue Exception => e
        if verbose?
          puts e.inspect
          puts e.backtrace
        end
        return [Page.new(url, :error => e)]
      end
    end

    #
    # The maximum number of redirects to follow
    #
    def redirect_limit
      @opts[:redirect_limit] || REDIRECT_LIMIT
    end

    #
    # The user-agent string which will be sent with each request,
    # or nil if no such option is set
    #
    def user_agent
      @opts[:user_agent]
    end

    #
    # Does this HTTP client accept cookies from the server?
    #
    def accept_cookies?
      @opts[:accept_cookies]
    end

    #
    # The http authentication options as in http://www.ruby-doc.org/stdlib/libdoc/open-uri/rdoc/OpenURI/OpenRead.html
    # userinfo is deprecated [RFC3986]
    #
    def http_basic_authentication
      @opts[:http_basic_authentication]
    end

    #
    # The proxy authentication options as in http://www.ruby-doc.org/stdlib/libdoc/open-uri/rdoc/OpenURI/OpenRead.html
    #
    def proxy_http_basic_authentication
      @opts[:proxy_http_basic_authentication]
    end

    #
    # The proxy options as in http://www.ruby-doc.org/stdlib/libdoc/open-uri/rdoc/OpenURI/OpenRead.html
    #
    def proxy
      @opts[:proxy]
    end

    #
    # The proxy address string
    #
    def proxy_host
      @opts[:proxy_host]
    end

    #
    # The proxy port
    #
    def proxy_port
      @opts[:proxy_port]
    end

    #
    # HTTP read timeout in seconds
    #
    def read_timeout
      @opts[:read_timeout]
    end

    private

    #
    # Retrieve HTTP responses for *url*, including redirects.
    # Yields the response object, response code, and URI location
    # for each response.
    #
    def get(url, referer = nil)
      limit = redirect_limit
      loc = url
      begin
          # if redirected to a relative url, merge it with the host of the original
          # request url
          loc = url.merge(loc) if loc.relative?

          response, headers, response_time, response_code, redirect_to = get_response(loc, referer)
          
          yield response, headers, Integer(response_code), loc, redirect_to, response_time
          limit -= 1
      end while (loc = redirect_to) && allowed?(redirect_to, url) && limit > 0
    end

    #
    # Get an HTTPResponse for *url*, sending the appropriate User-Agent string
    #
    def get_response(url, referer = nil)
      full_path = url.query.nil? ? url.path : "#{url.path}?#{url.query}"

      opts = {}
      opts['User-Agent'] = user_agent if user_agent
      opts['Referer'] = referer.to_s if referer
      opts['Cookie'] = @cookie_store.to_s unless @cookie_store.empty? || (!accept_cookies? && @opts[:cookies].nil?)
      opts[:http_basic_authentication] = http_basic_authentication if http_basic_authentication
      opts[:proxy] = proxy if proxy
      opts[:proxy_http_basic_authentication] = proxy_http_basic_authentication if proxy_http_basic_authentication
      opts[:read_timeout] = read_timeout if !!read_timeout
      opts[:redirect] = false
      redirect_to = nil
      retries = 0
      begin
        start = Time.now()

        begin
          resource = open(url, opts)
        rescue OpenURI::HTTPRedirect => e
          resource = e.io
          redirect_to = e.uri
        end

        finish = Time.now()
        response_time = ((finish - start) * 1000).round
        @cookie_store.merge!(resource.meta['set-cookie']) if accept_cookies?
        return resource.read, resource.meta, response_time, resource.status.shift, redirect_to

      rescue Timeout::Error, EOFError, Errno::ECONNREFUSED => e
        retries += 1
        puts "[anemone] Retrying ##{retries} on url #{url} because of: #{e.inspect}" if verbose?
        sleep(2 ^ retries)
        retry unless retries > 5
      ensure
        resource.close if !resource.nil? && !resource.closed?
      end
    end

    def verbose?
      @opts[:verbose]
    end

    #
    # Allowed to connect to the requested url?
    #
    def allowed?(to_url, from_url)
      to_url.host.nil? || (to_url.host == from_url.host)
    end
  end
end
