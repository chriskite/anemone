require 'rubygems'
require File.dirname(__FILE__) + '/fakeweb_helper'

$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'anemone'

SPEC_DOMAIN = 'http://www.example.com/'

# Don't modify this line - add the file spec/test_these_engines.rb and redefine this global
# to include/exclude custom engines if you don't have all the gems.
$TESTABLE_STORAGE_ENGINES = %w[redis pstore tokyo_cabinet mongodb]
optional_test_restrictions_file = File.dirname(__FILE__) + '/test_these_engines.rb'
require optional_test_restrictions_file if File.exist?(optional_test_restrictions_file)

def testing?(engine_name)
  $TESTABLE_STORAGE_ENGINES.include?(engine_name)
end

def require_storage_engines *engines
  engines.flatten.each { |engine| require "anemone/storage/#{engine}.rb" if testing?(engine) }
end
