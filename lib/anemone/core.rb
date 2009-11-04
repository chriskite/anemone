require 'thread'
require 'robots'
require 'anemone/tentacle'
require 'anemone/page'
require 'anemone/page_store'
require 'anemone/storage'

module Anemone

  VERSION = '0.3.0';

  #
  # Convenience method to start a crawl
  #
  def Anemone.crawl(urls, options = {}, &block)
    Core.crawl(urls, options, &block)
  end

  class Core
    # PageStore storing all Page objects encountered during the crawl
    attr_reader :pages

    # Hash of options for the crawl
    attr_accessor :opts

    DEFAULT_OPTS = {
      # run 4 Tentacle threads to fetch pages
      :threads => 4,
      # disable verbose output
      :verbose => false,
      # don't throw away the page response body after scanning it for links
      :discard_page_bodies => false,
      # identify self as Anemone/VERSION
      :user_agent => "Anemone/#{Anemone::VERSION}",
      # no delay between requests
      :delay => 0,
      # don't obey the robots exclusion protocol
      :obey_robots_txt => false,
      # by default, don't limit the depth of the crawl
      :depth_limit => false,
      # number of times HTTP redirects will be followed
      :redirect_limit => 5
    }

    #
    # Initialize the crawl with starting *urls* (single URL or Array of URLs)
    # and optional *block*
    #
    def initialize(urls, opts = {})
      @urls = [urls].flatten.map{ |url| url.is_a?(URI) ? url : URI(url) }
      @urls.each{ |url| url.path = '/' if url.path.empty? }

      @tentacles = []
      @pages = PageStore.new(opts[:storage] || Anemone::Storage.Hash)
      @on_every_page_blocks = []
      @on_pages_like_blocks = Hash.new { |hash,key| hash[key] = [] }
      @skip_link_patterns = []
      @after_crawl_blocks = []

      process_options opts

      yield self if block_given?
    end

    #
    # Convenience method to start a new crawl
    #
    def self.crawl(urls, opts = {})
      self.new(urls, opts) do |core|
        yield core if block_given?
        core.run
      end
    end

    #
    # Add a block to be executed on the PageStore after the crawl
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
      @skip_link_patterns.concat [patterns].flatten.compact
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
    # Specify a block which will select which links to follow on each page.
    # The block should return an Array of URI objects.
    #
    def focus_crawl(&block)
      @focus_crawl_block = block
      self
    end

    #
    # Perform the crawl
    #
    def run
      @urls.delete_if { |url| !visit_link?(url) }
      return if @urls.empty?

      link_queue = Queue.new
      page_queue = Queue.new

      @opts[:threads].times do
        @tentacles << Thread.new { Tentacle.new(link_queue, page_queue, @opts).run }
      end

      @urls.each{ |url| link_queue.enq(url) }

      loop do
        page = page_queue.deq

        puts "#{page.url} Queue: #{link_queue.size}" if @opts[:verbose]

        # perform the on_every_page blocks for this page
        do_page_blocks(page)

        page.discard_doc! if @opts[:discard_page_bodies]

        links = links_to_follow(page)
        links.each do |link|
          link_queue << [link, page]
        end
        @pages.set_keys_nil links

        # create an entry in the page hash for each alias of this page,
        # i.e. all the pages that redirected to this page
        page.aliases.each do |aka|
          if !@pages.has_key?(aka) or @pages[aka].nil?
            @pages[aka] = page.alias_clone(aka)
          end
          @pages[aka].add_alias!(page.url)
        end

        @pages[page.url] = page

        # if we are done with the crawl, tell the threads to end
        if link_queue.empty? and page_queue.empty?
          until link_queue.num_waiting == @tentacles.size
            Thread.pass
          end

          if page_queue.empty?
            @tentacles.size.times { link_queue.enq(:END)}
            break
          end
        end

      end

      @tentacles.each { |t| t.join }

      do_after_crawl_blocks()

      self
    end

    private

    def process_options(options)
      @opts = DEFAULT_OPTS.merge options

      @opts[:threads] = 1 if @opts[:delay] > 0

      @robots = Robots.new(@opts[:user_agent]) if @opts[:obey_robots_txt]
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
    # Return an Array of links to follow from the given page.
    # Based on whether or not the link has already been crawled,
    # and the block given to focus_crawl()
    #
    def links_to_follow(page)
      links = @focus_crawl_block ? @focus_crawl_block.call(page) : page.links
      links.select { |link| visit_link?(link, page) }
    end

    #
    # Returns +true+ if *link* has not been visited already,
    # and is not excluded by a skip_link pattern...
    # and is not excluded by robots.txt...
    # and is not deeper than the depth limit
    # Returns +false+ otherwise.
    #
    def visit_link?(link, from_page = nil)
      allowed = @opts[:obey_robots_txt] ? @robots.allowed?(link) : true

      if from_page && @opts[:depth_limit]
        too_deep = from_page.depth >= @opts[:depth_limit]
      else
        too_deep = false
      end

      !@pages.has_page?(link) && !skip_link?(link) && allowed && !too_deep
    end

    #
    # Returns +true+ if *link* should not be visited because
    # its URL matches a skip_link pattern.
    #
    def skip_link?(link)
      @skip_link_patterns.any? { |p| link.path =~ p }
    end

  end
end
