require 'ostruct'
require 'anemone/core'

module Anemone
  # Version number
  VERSION = '0.0.1'
  
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
  def Anemone.crawl(url, options = {}, &block)
    Anemone.options = OpenStruct.new(options)
	
	#by default, run 4 Tentacle threads to fetch pages
    Anemone.options.threads ||= 4
	
	#disable verbose output by default
    Anemone.options.verbose ||= false
	
	#by default, throw away the page response body after scanning it for links, to save memory
	Anemone.options.discard_page_bodies ||= true
	
    Core.crawl(url, &block)
  end
end