#! /usr/bin/env ruby
# == Synopsis
#   Crawls a site starting at the given URL, and outputs the URL of each page
#   in the domain as they are encountered.
#
# == Usage
#   anemone_url_list.rb [options] url
#
# == Options
#   -r, --relative          Output relative URLs (rather than absolute)
#
# == Author
#   Chris Kite

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'anemone'
require 'optparse'
require 'ostruct'

def usage
  puts <<END
Usage: anemone_url_list.rb [options] url
    
Options:
  -r, --relative      Output relative URLs (rather than absolute)
END
end

options = OpenStruct.new
options.relative = false

# make sure that the last option is a URL we can crawl
begin
  URI(ARGV.last)
rescue
  usage
  Process.exit 
end

# parse command-line options
opts = OptionParser.new
opts.on('-r', '--relative') { options.relative = true }
opts.parse!(ARGV)

Anemone.crawl(ARGV.last, :discard_page_bodies => true) do |anemone|  
  anemone.on_every_page do |page|
    if options.relative
      puts page.url.path
    else
      puts page.url
    end
  end
end
