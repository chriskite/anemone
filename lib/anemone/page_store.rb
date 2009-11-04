module Anemone
  class PageStore

    def initialize(storage = {})
      @storage = storage
    end

    # We typically index the hash with a URI,
    # but convert it to a String for easier retrieval
    def [](index)
      @storage[index.to_s]
    end

    def []=(index, other)
      @storage[index.to_s] = other
    end

    def has_key?(key)
      @storage.has_key?(key.to_s)
    end

    def keys
      @storage.keys
    end

    def values
      @storage.values
    end

    def size
      keys.size
    end

    def each
      keys.each { |key| yield key, self[key] }
    end

    def each_value
      values.each { |value| yield value }
    end

    def set_keys_nil keys
      if @storage.respond_to? :set_keys_nil
        @storage.set_keys_nil keys.map { |key| key.to_s }
      else
         keys.each { |key| self[key] = nil }
      end
    end

    # Does this PageStore contain the specified URL?
    # HTTP and HTTPS versions of a URL are considered to be the same page.
    def has_page?(url)
      schemes = %w(http https)
      if schemes.include? url.scheme
        u = url.dup
        return schemes.any? { |s| u.scheme = s; has_key?(u) }
      end

      has_key?(url)
    end

    #
    # Use a breadth-first search to calculate the single-source
    # shortest paths from *root* to all pages in the PageStore
    #
    def shortest_paths!(root)
      root = URI(root) if root.is_a?(String)
      raise "Root node not found" if !has_key?(root)

      each_value {|p| p.visited = false if p}

      q = Queue.new

      q.enq(root)
      self[root].depth = 0
      self[root].visited = true
      while(!q.empty?)
        url = q.deq

        next if !has_key?(url)

        page = self[url]

        page.links.each do |u|
          next if !has_key?(u) or self[u].nil?
          link = self[u]
          aliases = [link].concat(link.aliases.map {|a| self[a] })

          aliases.each do |node|
            if node.depth.nil? or page.depth + 1 < node.depth
              node.depth = page.depth + 1
            end
          end

          q.enq(self[u].url) if !self[u].visited
          self[u].visited = true
        end
      end

      self
    end

    #
    # Returns a new PageStore by removing redirect-aliases for each
    # non-redirect Page
    #
    def uniq
      results = PageStore.new
      each do |url, page|
        #if none of the aliases of this page have been added, and this isn't a redirect page, add this page
        page_added = page.aliases.inject(false) { |r, a| r ||= results.has_key? a}
        if !page.redirect? and !page_added
          results[url] = page.clone
          results[url].aliases = []
        end
      end

      results
    end

    #
    # If given a single URL (as a String or URI), returns an Array of Pages which link to that URL
    # If given an Array of URLs, returns a Hash (URI => [Page, Page...]) of Pages linking to those URLs
    #
    def pages_linking_to(urls)
      unless urls.is_a?(Array)
        urls = [urls] unless urls.is_a?(Array)
        single = true
      end

      urls.map! do |url|
        if url.is_a?(String)
          URI(url) rescue nil
        else
          url
        end
      end
      urls.compact

      links = {}
      urls.each { |url| links[url] = [] }
      values.each do |page|
        urls.each { |url| links[url] << page if page.links.include?(url) }
      end

      if single and !links.empty?
        return links.first
      else
        return links
      end
    end

    #
    # If given a single URL (as a String or URI), returns an Array of URLs which link to that URL
    # If given an Array of URLs, returns a Hash (URI => [URI, URI...]) of URLs linking to those URLs
    #
    def urls_linking_to(urls)
      unless urls.is_a?(Array)
        urls = [urls] unless urls.is_a?(Array)
        single = true
      end

      links = pages_linking_to(urls)
      links.each { |url, pages| links[url] = pages.map{|p| p.url} }

      if single and !links.empty?
        return links.first
      else
        return links
      end
    end

  end
end
