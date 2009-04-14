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
require 'rdoc/usage'
require 'ostruct'

options = OpenStruct.new
options.relative = false

# make sure that the last option is a URL we can crawl
begin
  URI(ARGV.last)
rescue
  RDoc::usage()
  Process.exit 
end

# parse command-line options
opts = OptionParser.new
opts.on('-r', '--relative') { options.relative = true }
opts.parse!(ARGV)

Anemone.crawl(ARGV.last) do |anemone|  
  anemone.on_every_page do |page|
    if options.relative
      puts page.url.path
    else
      puts page.url
    end
  end
end