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

    def delete(key)
      @storage.delete key
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
      @storage.size
    end

    def each
      keys.each { |key| yield key, self[key] }
    end

    def each_value
      values.each { |value| yield value }
    end

    def touch_keys keys
      @storage.merge! keys.inject({}) { |h, k| h[k.to_s] = Page.new(k); h }
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

      q = Queue.new

      q.enq(root)
      root_page = self[root]
      root_page.depth = 0
      root_page.visited = true
      self[root] = root_page
      while(!q.empty?)
        url = q.deq

        next if !has_key?(url)

        page = self[url]

        page.links.each do |u|
          p u
          next if !has_key?(u) or !self[u].fetched?
          puts "okeh"
          link = self[u]
          aliases = [link].concat(link.aliases.map {|a| self[a] })

          aliases.each do |node|
            if node.depth.nil? or page.depth + 1 < node.depth
              node.depth = page.depth + 1
              self[node.url] = node
            end
          end

          q.enq(self[u].url) if !self[u].visited
          link.visited = true
          self[u] = link
        end
      end

      self
    end

    #
    # Removes from storage the redirect-aliases for each non-redirect Page
    #
    def uniq!
      each_value do |page|
        page.aliases.each { |url| delete url } if !page.redirect?
      end

      self
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
