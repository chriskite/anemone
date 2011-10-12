require 'anemone/http'

module Anemone
  class Tentacle

    #
    # Create a new Tentacle
    #
    def initialize(link_queue, page_queue, opts = {})
      @link_queue = link_queue
      @page_queue = page_queue
      @http = Anemone::HTTP.new(opts)
      @opts = opts
    end

    #
    # Gets links from @link_queue, and returns the fetched
    # Page objects into @page_queue
    #
    def run
      pipe_good = true
      trap("SIGPIPE") { pipe_good = false ; puts "CAUGHT A PIPE IN TENTACLE!" if verbose? ;}
      loop do
       unless pipe_good
         break # Let them die in peace...?      	      
       end
       keep_alive = true
       fetched = false
       begin
         link, referer, depth = @link_queue.deq
         break if link == :END
	 @http.fetch_pages(link, referer, depth).each { |page| @page_queue << page }
         fetched = true
	 delay
       rescue
         if $!.inspect.to_s.include?("Errno::EPIPE")
           puts "Caught a SIGPIPE. You know the drill" if verbose?
	   puts "Attempting to kill this thread..." if verbose?
	   keep_alive = false
	 end
       ensure
########################
## DEPRECATED EXIT STRATEGY BELOW...
#########################
#         unless fetched
#           @http.fetch_pages(nil, nil, nil).each { |page| @page_queue << page }
#      	    puts "Forced to page fetch..."
#	 end
#########################
	 unless keep_alive
	   break # die, die, die...
 	 end
       end
      this_thread = Thread.current
      this_thread.kill ## Let's see what happens when we make this explicit...     
      end
    end

    private

    def verbose?
      @opts[:verbose]
    end

    def delay
      sleep @opts[:delay] if @opts[:delay] > 0
    end

  end
end
