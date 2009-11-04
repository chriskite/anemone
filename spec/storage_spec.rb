require File.dirname(__FILE__) + '/spec_helper'
%w[pstore tokyo_cabinet].each { |file| require "anemone/storage/#{file}.rb" }

module Anemone
  describe Storage do

    it "should have a class method to produce a Hash" do
      Anemone::Storage.should respond_to :Hash
      Anemone::Storage.Hash.should be_an_instance_of Hash
    end

    it "should have a class method to produce a PStore" do
      test_file = 'test.pstore'
      Anemone::Storage.should respond_to :PStore
      Anemone::Storage.PStore(test_file).should be_an_instance_of Anemone::Storage::PStore
    end

    it "should have a class method to produce a TokyoCabinet" do
      test_file = 'test.tch'
      Anemone::Storage.should respond_to :TokyoCabinet
      store = Anemone::Storage.TokyoCabinet(test_file)
      store.should be_an_instance_of Anemone::Storage::TokyoCabinet
      store.close
    end

    module Storage
      shared_examples_for "storage engine" do
        it "should implement [] and []=" do
          @store.should respond_to :[]
          @store.should respond_to :[]=

          @store['index'] = 'test'
          @store['index'].should == 'test'
        end

        it "should implement has_key?" do
          @store.should respond_to :has_key?

          @store['index'] = 'test'
          @store.has_key?('index').should == true

          @store.has_key?('missing').should == false
        end

        it "should implement delete" do
          @store.should respond_to :delete

          @store['index'] = 'test'
          @store.delete('index').should == 'test'
          @store.has_key?('index').should  == false
        end

        it "should implement keys" do
          @store.should respond_to :keys

          keys = ['a', 'b', 'c']
          keys.each { |key| @store[key] = key }

          @store.keys.should == keys
        end

        it "should implement values" do
          @store.should respond_to :values

          keys = ['a', 'b', 'c']
          keys.each { |key| @store[key] = key }

          @store.values.should == keys
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
      end

    end
  end
end
