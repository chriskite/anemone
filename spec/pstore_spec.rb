require File.dirname(__FILE__) + '/spec_helper'
require 'anemone/storage/pstore'

module Anemone
  module Storage
    describe PStore do

      before(:each) do
        @test_file = 'test.pstore'
        File.delete @test_file rescue nil
        @store =  Anemone::Storage.PStore(@test_file)
      end

      after(:all) do
        File.delete @test_file rescue nil
      end

      it "should implement [] and []=" do
        @store.should respond_to :[]
        @store.should respond_to :[]=

        @store[:index] = 'test'
        @store[:index].should == 'test'

        @store['index'] = 'test2'
        @store['index'].should == 'test2'
      end

      it "should implement has_key?" do
        @store.should respond_to :has_key?

        @store[:index] = 'test'
        @store.has_key?(:index).should == true

        @store.has_key?(:fake).should == false
      end

      it "should implement delete" do
        @store.should respond_to :delete

        @store[:index] = 'test'
        @store.delete(:index).should == 'test'
        @store.has_key?(:index).should  == false
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
  end
end
