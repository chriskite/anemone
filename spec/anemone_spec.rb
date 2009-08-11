require File.dirname(__FILE__) + '/spec_helper'

describe Anemone do

  it "should have a version" do
    Anemone.const_defined?('VERSION').should == true
  end

  it "should have options" do
    Anemone.should respond_to(:options)
  end
  
  it "should accept options for the crawl" do
    Anemone.crawl(SPEC_DOMAIN, :verbose => false, 
                               :threads => 2, 
                               :discard_page_bodies => true,
                               :user_agent => 'test')
    Anemone.options.verbose.should == false
    Anemone.options.threads.should == 2
    Anemone.options.discard_page_bodies.should == true
    Anemone.options.delay.should == 0
    Anemone.options.user_agent.should == 'test'
  end
  
  it "should use 1 thread if a delay is requested" do
    Anemone.crawl(SPEC_DOMAIN, :delay => 0.01, :threads => 2)
    Anemone.options.threads.should == 1
  end
  
  it "should return a Anemone::Core from the crawl, which has a PageHash" do
    result = Anemone.crawl(SPEC_DOMAIN)
    result.should be_an_instance_of(Anemone::Core)
    result.pages.should be_an_instance_of(Anemone::PageHash)
  end
  
end
