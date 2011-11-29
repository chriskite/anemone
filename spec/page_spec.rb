$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module Anemone
  describe Page do

    before(:each) do
      FakeWeb.clean_registry
      @http = Anemone::HTTP.new
      @page = @http.fetch_page(FakePage.new('home', :links => '1').url)
    end

    it "should indicate whether it successfully fetched via HTTP" do
      @page.should respond_to(:fetched?)
      @page.fetched?.should == true

      fail_page = @http.fetch_page(SPEC_DOMAIN + 'fail')
      fail_page.fetched?.should == false
    end

    it "should store and expose the response body of the HTTP request" do
      body = 'test'
      page = @http.fetch_page(FakePage.new('body_test', {:body => body}).url)
      page.body.should == body
    end

    it "should record any error that occurs during fetch_page" do
      @page.should respond_to(:error)
      @page.error.should be_nil

      fail_page = @http.fetch_page(SPEC_DOMAIN + 'fail')
      fail_page.error.should_not be_nil
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

      @http.fetch_pages(FakePage.new('redir', :redirect => 'home').url).first.redirect?.should == true
    end

    it "should have a method to tell if a URI is in the same domain as the page" do
      @page.should respond_to(:in_domain?)

      @page.in_domain?(URI(FakePage.new('test').url)).should == true
      @page.in_domain?(URI('http://www.other.com/')).should == false
    end

    it "should include the response time for the HTTP request" do
      @page.should respond_to(:response_time)
    end

    it "should have the cookies received with the page" do
      @page.should respond_to(:cookies)
      @page.cookies.should == []
    end

    it "should have a to_hash method that converts the page to a hash" do
      hash = @page.to_hash
      hash['url'].should == @page.url.to_s
      hash['referer'].should == @page.referer.to_s
      hash['links'].should == @page.links.map(&:to_s)
    end

    it "should have a from_hash method to convert from a hash to a Page" do
      page = @page.dup
      page.depth = 1
      converted = Page.from_hash(page.to_hash)
      converted.links.should == page.links
      converted.depth.should == page.depth
    end

    it "should detect, store and expose the base url for the page head" do
      base = "#{SPEC_DOMAIN}path/to/base_url/"
      page = @http.fetch_page(FakePage.new('body_test', {:base => base}).url)
      page.base.should == URI(base)
      @page.base.should be_nil
    end

    it "should have a method to convert a relative url to an absolute one" do
      @page.should respond_to(:to_absolute)
      
      # Identity
      @page.to_absolute(@page.url).should == @page.url
      @page.to_absolute("").should == @page.url
      
      # Root-ness
      @page.to_absolute("/").should == URI("#{SPEC_DOMAIN}")
      
      # Relativeness
      relative_path = "a/relative/path"
      @page.to_absolute(relative_path).should == URI("#{SPEC_DOMAIN}#{relative_path}")
      
      deep_page = @http.fetch_page(FakePage.new('home/deep', :links => '1').url)
      upward_relative_path = "../a/relative/path"
      deep_page.to_absolute(upward_relative_path).should == URI("#{SPEC_DOMAIN}#{relative_path}")
      
      # The base URL case
      base_path = "path/to/base_url/"
      base = "#{SPEC_DOMAIN}#{base_path}"
      page = @http.fetch_page(FakePage.new('home', {:base => base}).url)
      
      # Identity
      page.to_absolute(page.url).should == page.url
      # It should revert to the base url
      page.to_absolute("").should_not == page.url

      # Root-ness
      page.to_absolute("/").should == URI("#{SPEC_DOMAIN}")
      
      # Relativeness
      relative_path = "a/relative/path"
      page.to_absolute(relative_path).should == URI("#{base}#{relative_path}")
      
      upward_relative_path = "../a/relative/path"
      upward_base = "#{SPEC_DOMAIN}path/to/"
      page.to_absolute(upward_relative_path).should == URI("#{upward_base}#{relative_path}")      
    end

  end
end
