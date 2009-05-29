#! /usr/bin/env ruby
# == Synopsis
#   Crawls a site starting at the given URL, and outputs a count of
#   the number of Pages at each depth in the site.
#
# == Usage
#   anemone_pagedepth.rb url
#
# == Author
#   Chris Kite

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'anemone'

def usage
  puts <<END
Usage: anemone_pagedepth.rb url
END
end

# make sure that the first option is a URL we can crawl
begin
  URI(ARGV[0])
rescue
  usage
  Process.exit 
end

root = ARGV[0]
Anemone.crawl(root) do |anemone|
  anemone.skip_links_like %r{^/c/$}, %r{^/stores/$}
  
  anemone.after_crawl do |pages|
    pages = pages.shortest_paths!(root).uniq
    depths = pages.values.inject({}) do |depths, page|
      depths[page.depth] ||= 0
      depths[page.depth] += 1
      depths
    end
    
    depths.sort.each { |depth, count| puts "Depth: #{depth} Count: #{count}" }
  end
end