require File.dirname(__FILE__) + '/spec_helper'

module Anemone
  describe Page do
    
    before(:each) do
      @page = Page.fetch(FakePage.new('home').url)
    end
    
    it "should be able to fetch a page" do
      @page.should_not be_nil
      @page.url.to_s.should include('home')
    end
    
    it "should store the response headers when fetching a page" do
      @page.headers.should_not be_nil
      @page.headers.should have_key('content-type')
    end
    
    it "should have an OpenStruct attribute for the developer to store data in" do
      @page.data.should_not be_nil
      @page.data.should be_an_instance_of(OpenStruct)
      
      @page.data.test = 'test'
      @page.data.test.should == 'test'
    end
    
    it "should have a Nokogori::HTML::Document attribute for the page body" do
      @page.doc.should_not be_nil
      @page.doc.should be_an_instance_of(Nokogiri::HTML::Document)
    end
    
    it "should indicate whether it was fetched after an HTTP redirect" do
      @page.should respond_to(:redirect?)
      
      @page.redirect?.should == false
      
      Page.fetch(FakePage.new('redir', :redirect => 'home').url).redirect?.should == true
    end
    
    it "should have a method to tell if a URI is in the same domain as the page" do
      @page.should respond_to(:in_domain?)
      
      @page.in_domain?(URI(FakePage.new('test').url)).should == true
      @page.in_domain?(URI('http://www.other.com/')).should == false
    end
    
  end
end
