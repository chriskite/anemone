require 'ostruct'
require 'anemone/core'

module Anemone
  # Version number
  VERSION = '0.2.2'
  
  # default options
  DEFAULTS = {
    # run 4 Tentacle threads to fetch pages
    :threads => 4,
    # disable verbose output
    :verbose => false,
    # don't throw away the page response body after scanning it for links
    :discard_page_bodies => false,
    # identify self as Anemone/VERSION
    :user_agent => "Anemone/#{VERSION}",
    # no delay between requests
    :delay => 0,
    # don't obey the robots exclusion protocol
    :obey_robots_txt => false,
    # by default, don't limit the depth of the crawl
    :depth_limit => false,
    # number of times HTTP redirects will be followed
    :redirect_limit => 5
  }

  def self.options
    @options ||= OpenStruct.new(DEFAULTS)
  end
  
  #
  # Convenience method to start a crawl using Core
  #
  def Anemone.crawl(urls, options = {}, &block)
    options.each { |key, value| Anemone.options.send("#{key}=", value) }

    if Anemone.options.obey_robots_txt
      begin
      require 'robots'
      rescue LoadError
        warn "To support the robot exclusion protocol, install the robots gem:\n" \
          "sudo gem sources -a http://gems.github.com\n" \
          "sudo gem install fizx-robots"
        exit
      end
    end

    #use a single thread if a delay was requested
    Anemone.options.threads = 1 if Anemone.options.delay > 0

    Core.crawl(urls, &block)
  end
end
