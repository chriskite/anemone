require 'net/http'
require 'thread'
require 'anemone/tentacle'
require 'anemone/page_hash'

module Anemone
  class Core
    # PageHash storing all Page objects encountered during the crawl
    attr_reader :pages
    
    #
    # Initialize the crawl with a starting *url*, *options*, and optional *block*
    #
    def initialize(url, &block)
      url = URI(url) if url.is_a?(String)
      @url = url
      @tentacles = []
      @pages = PageHash.new
      @on_every_page_blocks = []
      @on_pages_like_blocks = Hash.new { |hash,key| hash[key] = [] }
      @skip_link_patterns = []
      @after_crawl_blocks = []
      
      block.call(self) if block
    end
    
    #
    # Convenience method to start a new crawl
    #
    def self.crawl(root, &block)
      self.new(root) do |core|
        block.call(core) if block
        core.run
        core.do_after_crawl_blocks
        return core
      end
    end
    
    #
    # Add a block to be executed on the PageHash after the crawl
    # is finished
    #
    def after_crawl(&block)
      @after_crawl_blocks << block
      self
    end
    
    #
    # Add one ore more Regex patterns for URLs which should not be
    # followed
    #
    def skip_links_like(*patterns)
      if patterns
        patterns.each do |pattern|
          @skip_link_patterns << pattern
        end
      end
      self
    end
    
    #
    # Add a block to be executed on every Page as they are encountered
    # during the crawl
    #
    def on_every_page(&block)
      @on_every_page_blocks << block
      self
    end
    
    #
    # Add a block to be executed on Page objects with a URL matching
    # one or more patterns
    #
    def on_pages_like(*patterns, &block)
      if patterns
        patterns.each do |pattern|
          @on_pages_like_blocks[pattern] << block
        end
      end
      self
    end
    
    #
    # Perform the crawl
    #
    def run
      link_queue = Queue.new
      page_queue = Queue.new

      Anemone.options.threads.times do |id|
        @tentacles << Thread.new { Tentacle.new(link_queue, page_queue).run }
      end
      
      return if !visit_link?(@url)
      
      link_queue.enq(@url)

      while true do
        page = page_queue.deq
        
        @pages[page.url] = page
        
        puts "#{page.url} Queue: #{link_queue.size}" if Anemone.options.verbose
        
        do_page_blocks(page)

        page.body = nil if Anemone.options.discard_page_bodies
        
        page.links.each do |link| 
          if visit_link?(link)
            link_queue.enq(link)
            @pages[link] = nil
          end
        end
        
        page.aliases.each do |aka|
          if !@pages.has_key?(aka) or @pages[aka].nil?
            @pages[aka] = page.alias_clone(aka)
          end
          @pages[aka].add_alias!(page.url)
        end
        
        # if we are done with the crawl, tell the threads to end
        if link_queue.empty? and page_queue.empty?
          until link_queue.num_waiting == @tentacles.size
            Thread.pass
          end
          
          if page_queue.empty?
            @tentacles.size.times { |i| link_queue.enq(:END)}
            break
          end
        end
        
      end

      @tentacles.each { |t| t.join }

      self
    end
    
    #
    # Execute the after_crawl blocks
    #
    def do_after_crawl_blocks
      @after_crawl_blocks.each {|b| b.call(@pages)}
    end
    
    #
    # Execute the on_every_page blocks for *page*
    #
    def do_page_blocks(page)
      @on_every_page_blocks.each do |blk|
        blk.call(page)
      end
      
      @on_pages_like_blocks.each do |pattern, blks|
        if page.url.to_s =~ pattern
          blks.each { |blk| blk.call(page) }
        end
      end
    end      
    
    #
    # Returns +true+ if *link* has not been visited already,
    # and is not excluded by a skip_link pattern. Returns
    # +false+ otherwise.
    #
    def visit_link?(link)
      !@pages.has_key?(link) and !skip_link?(link)
    end
    
    #
    # Returns +true+ if *link* should not be visited because
    # its URL matches a skip_link pattern.
    #
    def skip_link?(link)
      @skip_link_patterns.each { |p| return true if link.path =~ p}
      return false
    end
    
  end
end
