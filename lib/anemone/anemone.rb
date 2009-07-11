require 'ostruct'
require 'anemone/core'

module Anemone
  # Version number
  VERSION = '0.1.0'
  
  # User-Agent string used for HTTP requests
  USER_AGENT = "Anemone/#{self::VERSION}"
  
  #module-wide options
  def Anemone.options=(options)
    @options = options
  end
  
  def Anemone.options
    @options
  end
  
  #
  # Convenience method to start a crawl using Core
  #
  def Anemone.crawl(urls, options = {}, &block)
    Anemone.options = OpenStruct.new(options)
	
    #by default, run 4 Tentacle threads to fetch pages
    Anemone.options.threads ||= 4
	
    #disable verbose output by default
    Anemone.options.verbose ||= false
	
    #by default, don't throw away the page response body after scanning it for links
    Anemone.options.discard_page_bodies ||= false
	
    Core.crawl(urls, &block)
  end
end
