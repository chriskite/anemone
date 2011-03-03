$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
%w[pstore tokyo_cabinet sqlite3 mongodb redis].each { |file| require "anemone/storage/#{file}.rb" }

module Anemone
  describe PageStore do

    before(:all) do
      FakeWeb.clean_registry
    end

    shared_examples_for "page storage" do
      it "should be able to compute single-source shortest paths in-place" do
        pages = []
        pages << FakePage.new('0', :links => ['1', '3'])
        pages << FakePage.new('1', :redirect => '2')
        pages << FakePage.new('2', :links => ['4'])
        pages << FakePage.new('3')
        pages << FakePage.new('4')

        # crawl, then set depths to nil
        page_store = Anemone.crawl(pages.first.url, @opts) do |a|
          a.after_crawl do |ps|
            ps.each { |url, page| page.depth = nil; ps[url] = page }
          end
        end.pages

        page_store.should respond_to(:shortest_paths!)

        page_store.shortest_paths!(pages[0].url)
        page_store[pages[0].url].depth.should == 0
        page_store[pages[1].url].depth.should == 1
        page_store[pages[2].url].depth.should == 1
        page_store[pages[3].url].depth.should == 1
        page_store[pages[4].url].depth.should == 2
      end

      it "should be able to remove all redirects in-place" do
        pages = []
        pages << FakePage.new('0', :links => ['1'])
        pages << FakePage.new('1', :redirect => '2')
        pages << FakePage.new('2')

        page_store = Anemone.crawl(pages[0].url, @opts).pages

        page_store.should respond_to(:uniq!)

        page_store.uniq!
        page_store.has_key?(pages[1].url).should == false
        page_store.has_key?(pages[0].url).should == true
        page_store.has_key?(pages[2].url).should == true
      end

      it "should be able to find pages linking to a url" do
        pages = []
        pages << FakePage.new('0', :links => ['1'])
        pages << FakePage.new('1', :redirect => '2')
        pages << FakePage.new('2')

        page_store = Anemone.crawl(pages[0].url, @opts).pages

        page_store.should respond_to(:pages_linking_to)

        page_store.pages_linking_to(pages[2].url).size.should == 0
        links_to_1 = page_store.pages_linking_to(pages[1].url)
        links_to_1.size.should == 1
        links_to_1.first.should be_an_instance_of(Page)
        links_to_1.first.url.to_s.should == pages[0].url
      end

      it "should be able to find urls linking to a url" do
        pages = []
        pages << FakePage.new('0', :links => ['1'])
        pages << FakePage.new('1', :redirect => '2')
        pages << FakePage.new('2')

        page_store = Anemone.crawl(pages[0].url, @opts).pages

        page_store.should respond_to(:pages_linking_to)

        page_store.urls_linking_to(pages[2].url).size.should == 0
        links_to_1 = page_store.urls_linking_to(pages[1].url)
        links_to_1.size.should == 1
        links_to_1.first.to_s.should == pages[0].url
      end
    end

    describe Hash do
      it_should_behave_like "page storage"

      before(:all) do
        @opts = {}
      end
    end

    describe Storage::PStore do
      it_should_behave_like "page storage"

      before(:each) do
        @test_file = 'test.pstore'
        File.delete(@test_file) if File.exists?(@test_file)
        @opts = {:storage => Storage.PStore(@test_file)}
      end

      after(:each) do
        File.delete(@test_file) if File.exists?(@test_file)
      end
    end

    describe Storage::TokyoCabinet do
      it_should_behave_like "page storage"

      before(:each) do
        @test_file = 'test.tch'
        File.delete(@test_file) if File.exists?(@test_file)
        @opts = {:storage => @store = Storage.TokyoCabinet(@test_file)}
      end

      after(:each) do
        @store.close
      end

      after(:each) do
        File.delete(@test_file) if File.exists?(@test_file)
      end
    end

    describe Storage::SQLite3 do
      it_should_behave_like "page storage"

      before(:each) do
        @test_file = 'test.db'
        File.delete(@test_file) if File.exists?(@test_file)
        @opts = {:storage => @store = Storage.SQLite3(@test_file)}
      end

      after(:each) do
        @store.close
      end

      after(:each) do
        File.delete(@test_file) if File.exists?(@test_file)
      end
    end

    describe Storage::MongoDB do
      it_should_behave_like "page storage"

      before(:each) do
        @opts = {:storage => @store = Storage.MongoDB}
      end

      after(:each) do
        @store.close
      end
    end

    describe Storage::Redis do
      it_should_behave_like "page storage"

      before(:each) do
        @opts = {:storage => @store = Storage.Redis}
      end

      after(:each) do
        @store.close
      end
    end

  end
end
