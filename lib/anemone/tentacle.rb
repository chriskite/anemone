require 'anemone/http'

module Anemone
  class Tentacle

    #
    # Create a new Tentacle
    #
    def initialize(link_queue, page_queue, page_counter, sync_counter, opts = {})
      @link_queue = link_queue
      @page_queue = page_queue
      @page_counter = page_counter
      @sync_counter = sync_counter
      @http = Anemone::HTTP.new(opts)
      @opts = opts
    end

    #
    # Gets links from @link_queue, and returns the fetched
    # Page objects into @page_queue
    #
    def run
      loop do
        link, referer, depth = @link_queue.deq

        break if link == :END

        current_counter = nil
        if @opts[:limit_pages]
          @sync_counter.synchronize {
            current_counter = @page_counter.value
          }
        end

        result = []
        if !current_counter || current_counter < @opts[:limit_pages]
          result = @http.fetch_pages(link, referer, depth)
        end

        result = result.take(@opts[:limit_pages] - current_counter) if current_counter

        result.each { |page| @page_queue << page }

        if current_counter && result.count > 0
          @sync_counter.synchronize {
            @page_counter.value += result.count
          }
        end

        delay
      end
    end

    private

    def delay
      sleep @opts[:delay] if @opts[:delay] > 0
    end

  end
end
