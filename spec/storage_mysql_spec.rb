$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

require 'anemone/storage/mysql.rb

module Anemone
  describe Storage do

    describe ".MySQL" do
      it "returns a MySQL adapter" do
        store = Anemone::Storage.MySQL
        store.should be_an_instance_of(Anemone::Storage::MySQL)
        store.close
      end
    end

    module Storage
      shared_examples_for "storage engine" do

        before(:each) do
          @url = SPEC_DOMAIN
          @page = Page.new(URI(@url))
        end

        it "should implement [] and []=" do
          @store.should respond_to(:[])
          @store.should respond_to(:[]=)

          @store[@url] = @page 
          @store[@url].url.should == URI(@url)
        end

        it "should implement has_key?" do
          @store.should respond_to(:has_key?)

          @store[@url] = @page
          @store.has_key?(@url).should == true

          @store.has_key?('missing').should == false
        end

        it "should implement delete" do
          @store.should respond_to(:delete)

          @store[@url] = @page
          @store.delete(@url).url.should == @page.url
          @store.has_key?(@url).should  == false
        end

        it "should implement keys" do
          @store.should respond_to(:keys)

          urls = [SPEC_DOMAIN, SPEC_DOMAIN + 'test', SPEC_DOMAIN + 'another']
          pages = urls.map { |url| Page.new(URI(url)) }
          urls.zip(pages).each { |arr| @store[arr[0]] = arr[1] }

          (@store.keys - urls).should == [] 
        end

        it "should implement each" do
          @store.should respond_to(:each)

          urls = [SPEC_DOMAIN, SPEC_DOMAIN + 'test', SPEC_DOMAIN + 'another']
          pages = urls.map { |url| Page.new(URI(url)) }
          urls.zip(pages).each { |arr| @store[arr[0]] = arr[1] }

          result = {}
          @store.each { |k, v| result[k] = v }
          (result.keys - urls).should == [] 
          (result.values.map { |page| page.url.to_s } - urls).should == []
        end

        it "should implement merge!, and return self" do
          @store.should respond_to(:merge!)

          hash = {SPEC_DOMAIN => Page.new(URI(SPEC_DOMAIN)),
                  SPEC_DOMAIN + 'test' => Page.new(URI(SPEC_DOMAIN + 'test'))}
          merged = @store.merge! hash
          hash.each { |key, value| @store[key].url.to_s.should == key }

          merged.should === @store
        end

        it "should correctly deserialize nil redirect_to when loading" do
          @page.redirect_to.should be_nil
          @store[@url] = @page 
          @store[@url].redirect_to.should be_nil
        end
      end

      describe PStore do
        it_should_behave_like "storage engine"

        before(:each) do
          @test_file = 'test.pstore'
          File.delete @test_file rescue nil
          @store =  Anemone::Storage.PStore(@test_file)
        end

        after(:all) do
          File.delete @test_file rescue nil
        end
      end

      describe MySQL do
        it_should_behave_like "storage engine"

        before(:each) do
          @test_file = 'test.db'
          File.delete @test_file rescue nil
          @store =  Anemone::Storage.SQLite3(@test_file)
        end

        after(:each) do
          @store.close
        end

        after(:all) do
          File.delete @test_file rescue nil
        end

      end

    end
  end
end
