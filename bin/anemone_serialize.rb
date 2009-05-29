#! /usr/bin/env ruby
# == Synopsis
#   Crawls a site starting at the given URL, and saves the resulting
#   PageHash object to a file using Marshal serialization.
#
# == Usage
#   anemone_serialize.rb [options] url
#
# == Options
#   -o, --output filename           Filename to save PageHash to. Defaults to crawl.{Time.now}
#
# == Author
#   Chris Kite

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'anemone'
require 'optparse'
require 'ostruct'

def usage
  puts <<END
Usage: anemone_serialize.rb [options] url

Options:
  -o, --output filename      Filename to save PageHash to. Defaults to crawl.{Time.now}
END
end

# make sure that the first option is a URL we can crawl
begin
  URI(ARGV[0])
rescue
  usage
  Process.exit 
end

options = OpenStruct.new
options.output_file = "crawl.#{Time.now.to_i}"

# parse command-line options
opts = OptionParser.new
opts.on('-o', '--output filename') {|o| options.output_file = o }
opts.parse!(ARGV)

root = ARGV[0]
Anemone.crawl(root) do |anemone|
  anemone.after_crawl do |pages|
    open(options.output_file, 'w') {|f| Marshal.dump(pages, f)}
  end
end