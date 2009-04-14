module Anemone
  class PageHash < Hash
    
    #
    # Use a breadth-first search to calculate the single-source
    # shortest paths from *root* to all pages in the PageHash
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
    # Returns a new PageHash by removing redirect-aliases for each
    # non-redirect Page
    #
    def uniq
      results = PageHash.new
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
    # Return an Array of Page objects which link to the given url
    #
    def pages_linking_to url
      begin
        url = URI(url) if url.is_a?(String)
      rescue
        return []
      end
      
      values.delete_if { |p| !p.links.include?(url) }
    end
    
    #
    # Return an Array of URI objects of Pages linking to the given url
    def urls_linking_to url
      pages_linking_to(url).map{|p| p.url}
    end
    
  end
end