require 'anemone/http'

module Anemone
  class Tentacle
    
    #
    # Create a new Tentacle
    #
    def initialize(link_queue, page_queue)
      @link_queue = link_queue
      @page_queue = page_queue
      @http = Anemone::HTTP.new
    end
    
    #
    # Gets links from @link_queue, and returns the fetched
    # Page objects into @page_queue
    #
    def run
      loop do
        link, from_page = @link_queue.deq
        
        break if link == :END
        
        if from_page
          page = @http.fetch_page(link, from_page)
        else
          page = @http.fetch_page(link)
        end
        
        @page_queue.enq(page)

        sleep Anemone.options.delay
      end
    end

  end
end