require File.dirname(__FILE__) + '/spec_helper'

describe Anemone do

  it "should have a version and user agent" do
    Anemone.const_defined?('VERSION').should == true
    Anemone.const_defined?('USER_AGENT').should == true
  end

  it "should have options" do
    Anemone.respond_to?('options').should == true
  end
  
  it "should accept options for the crawl" do
    Anemone.crawl(SPEC_DOMAIN, :verbose => false, :threads => 2, :discard_page_bodies => true)
    Anemone.options.verbose.should == false
    Anemone.options.threads.should == 2
    Anemone.options.discard_page_bodies.should == true
  end
  
  it "should return a Anemone::Core from the crawl, which has a PageHash" do
    result = Anemone.crawl(SPEC_DOMAIN)
    result.should be_an_instance_of(Anemone::Core)
    result.pages.should be_an_instance_of(Anemone::PageHash)
  end
  
end
