$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

%w[default redis].each { |file| require "anemone/queue/#{file}.rb" }

module Anemone
  describe Queue do

    it "should have a class method to produce a default queue" do
      Anemone::Queue.should respond_to(:Default)
      Anemone::Queue.Default.should be_an_instance_of(Queue::Default)
    end

    it "should have a class method to produce a Redis queue" do
      Anemone::Queue.should respond_to(:Redis)
      Anemone::Queue.Redis.should be_an_instance_of(Queue::Redis)
    end

    module Queue
      shared_examples_for :an_adapter do

        it 'should implement << and deq' do
          @queue.should respond_to(:<<)
          @queue.should respond_to(:deq)
          @queue << 'test'
          @queue.deq.should == 'test'
        end

        it 'should implement empty?' do
          @queue.should respond_to(:empty?)

          @queue.empty?.should be_true

          @queue << 'test'
          @queue.empty?.should be_false

          @queue.deq
          @queue.empty?.should be_true
        end

        it 'should implement size' do
          @queue.should respond_to(:size)

          @queue.size.should == 0

          @queue << 'test'
          @queue.size.should == 1
        end

        it 'should implement num_waiting' do
          @queue.should respond_to(:num_waiting)
        end

        it 'should implement clear' do
          @queue.should respond_to(:clear)

          @queue << 'test'
          @queue.clear
          @queue.size.should == 0
        end

      end

      describe Default do
        it_should_behave_like :an_adapter

        before(:each) { @queue = Anemone::Queue.Default }
        after(:all)   { @queue = nil }
      end

      describe Redis do
        #it_should_behave_like :an_adapter #TODO
      end

    end
  end
end