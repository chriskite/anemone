#! /usr/bin/env ruby
# == Synopsis
#   Crawls a site starting at the given URL, and outputs the total number
#   of unique pages on the site.
#
# == Usage
#   anemone_count.rb url
#
# == Author
#   Chris Kite

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'anemone'

def usage
  puts <<END
Usage: anemone_count.rb url
END
end

# make sure that the first option is a URL we can crawl
begin
  URI(ARGV[0])
rescue
  usage
  Process.exit 
end

Anemone.crawl(ARGV[0]) do |anemone|
  anemone.after_crawl do |pages|
    puts pages.uniq.size
  end
end


