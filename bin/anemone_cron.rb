#! /usr/bin/env ruby
# == Synopsis
#   Performs pagedepth, url list, and count functionality
#   Meant to be run daily as a cron job
#
# == Usage
#   anemone_url_list.rb [options] url
#
# == Options
#   -r, --relative                  Output relative URLs (rather than absolute)
#   -o, --output filename           Filename to save URL list to. Defaults to urls.txt.
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
  -r, --relative           Output relative URLs (rather than absolute)
  -o, --output filename    Filename to save URL list to. Defautls to urls.txt.
END
end

options = OpenStruct.new
options.relative = false
options.output_file = 'urls.txt'

# make sure that the last option is a URL we can crawl
begin
  URI(ARGV.last)
rescue
  usage
  Process.exit 
end

# parse command-line options
opts = OptionParser.new
opts.on('-r', '--relative')        { options.relative = true }
opts.on('-o', '--output filename') {|o| options.output_file = o }
opts.parse!(ARGV)

root = ARGV.last

Anemone.crawl(root, {:discard_page_bodies => true}) do |anemone|  
  
  anemone.after_crawl do |pages|
    puts "Crawl results for #{root}\n"
    
    # print a list of 404's
    not_found = []
    pages.each_value do |page|
      url = page.url.to_s
      not_found << url if page.not_found?
    end
    unless not_found.empty?
      puts "\n404's:"

      missing_links = pages.urls_linking_to(not_found)
      missing_links.each do |url, links|
        if options.relative
          puts URI(url).path.to_s
        else
          puts url
        end
        links.slice(0..10).each do |u|
          u = u.path if options.relative
          puts "  linked from #{u}"
        end
        
        puts " ..." if links.size > 10
      end

      print "\n"
    end  
    
    # remove redirect aliases, and calculate pagedepths
    pages = pages.shortest_paths!(root).uniq
    depths = pages.values.inject({}) do |depths, page|
      depths[page.depth] ||= 0
      depths[page.depth] += 1
      depths
    end
    
    # print the page count
    puts "Total pages: #{pages.size}\n"
    
    # print a list of depths
    depths.sort.each { |depth, count| puts "Depth: #{depth} Count: #{count}" }
    
    # output a list of urls to file
    file = open(options.output_file, 'w')
    pages.each_key do |url|
      url = options.relative ? url.path.to_s : url.to_s
      file.puts url
    end
    
  end
end