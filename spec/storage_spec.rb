$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

%w[pstore tokyo_cabinet mongodb redis].each { |file| require "anemone/storage/#{file}.rb" }

module Anemone
  describe Storage do

    it "should have a class method to produce a Hash" do
      Anemone::Storage.should respond_to(:Hash)
      Anemone::Storage.Hash.should be_an_instance_of(Hash)
    end

    it "should have a class method to produce a PStore" do
      test_file = 'test.pstore'
      Anemone::Storage.should respond_to(:PStore)
      Anemone::Storage.PStore(test_file).should be_an_instance_of(Anemone::Storage::PStore)
    end

    it "should have a class method to produce a TokyoCabinet" do
      test_file = 'test.tch'
      Anemone::Storage.should respond_to(:TokyoCabinet)
      store = Anemone::Storage.TokyoCabinet(test_file)
      store.should be_an_instance_of(Anemone::Storage::TokyoCabinet)
      store.close
    end

    it "should have a class method to produce a MongoDB" do
      Anemone::Storage.should respond_to(:MongoDB)
      store = Anemone::Storage.MongoDB
      store.should be_an_instance_of(Anemone::Storage::MongoDB)
      store.close
    end

    it "should have a class method to produce a Redis" do
      Anemone::Storage.should respond_to(:Redis)
      store = Anemone::Storage.Redis
      store.should be_an_instance_of(Anemone::Storage::Redis)
      store.close
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

      describe TokyoCabinet do
        it_should_behave_like "storage engine"

        before(:each) do
          @test_file = 'test.tch'
          File.delete @test_file rescue nil
          @store =  Anemone::Storage.TokyoCabinet(@test_file)
        end

        after(:each) do
          @store.close
        end

        after(:all) do
          File.delete @test_file rescue nil
        end

        it "should raise an error if supplied with a file extension other than .tch" do
          lambda { Anemone::Storage.TokyoCabinet('test.tmp') }.should raise_error(RuntimeError)
        end
      end

      describe Storage::MongoDB do
        it_should_behave_like "storage engine"

        before(:each) do
          @store = Storage.MongoDB
        end

        after(:each) do
          @store.close
        end
      end

      describe Storage::Redis do
        it_should_behave_like "storage engine"

        before(:each) do
          @store = Storage.Redis
        end

        after(:each) do
          @store.close
        end
      end

    end
  end
end
