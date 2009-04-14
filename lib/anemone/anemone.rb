require 'anemone/core'

module Anemone
  # Version number
  VERSION = '0.0.1'
  
  # User-Agent string used for HTTP requests
  USER_AGENT = "Anemone/#{self::VERSION}"
  
  #
  # Convenience method to start a crawl using Core
  #
  def Anemone.crawl(url, options = {}, &block)
    Core.crawl(url, options, &block)
  end
end