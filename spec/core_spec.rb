require File.dirname(__FILE__) + '/spec_helper'

module Anemone
  describe Core do
    
    before(:each) do
      FakeWeb.clean_registry
    end
    
    it "should crawl all the html pages in a domain by following <a> href's" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1', :links => ['3'])
      pages << FakePage.new('2')
      pages << FakePage.new('3')
      
      Anemone.crawl(pages[0].url).should have(4).pages
    end
    
    it "should not leave the original domain" do
      pages = []
      pages << FakePage.new('0', :links => ['1'], :hrefs => 'http://www.other.com/')
      pages << FakePage.new('1')
      
      core = Anemone.crawl(pages[0].url)
      
      core.should have(2).pages
      core.pages.keys.map{|k| k.to_s}.should_not include('http://www.other.com/')
    end
    
    it "should follow http redirects" do
      pages = []
      pages << FakePage.new('0', :links => ['1'])
      pages << FakePage.new('1', :redirect => '2')
      pages << FakePage.new('2')
      
      Anemone.crawl(pages[0].url).should have(3).pages     
    end
    
    it "should accept multiple starting URLs" do
      pages = []
      pages << FakePage.new('0', :links => ['1'])
      pages << FakePage.new('1')
      pages << FakePage.new('2', :links => ['3'])
      pages << FakePage.new('3')
      
      Anemone.crawl([pages[0].url, pages[2].url]).should have(4).pages
    end
    
    it "should include the query string when following links" do
      pages = []
      pages << FakePage.new('0', :links => ['1?foo=1'])
      pages << FakePage.new('1?foo=1')
      pages << FakePage.new('1')
      
      core = Anemone.crawl(pages[0].url)
      
      core.should have(2).pages
      core.pages.keys.map{|k| k.to_s}.should_not include(pages[2].url)
    end
    
  end
end
