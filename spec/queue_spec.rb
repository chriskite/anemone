$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

%w[basic redis].each { |file| require "anemone/queue/#{file}.rb" }

module Anemone
  describe Queue do

    it "should have a class method to produce a default queue" do
      Anemone::Queue.should respond_to(:Basic)
      Anemone::Queue.Basic.should be_an_instance_of(Queue::Basic)
    end

    it "should have a class method to produce a Redis queue" do
      Anemone::Queue.should respond_to(:Redis)
      Anemone::Queue.Redis.should be_an_instance_of(Queue::Redis)
    end

    module Queue
      shared_examples_for :an_adapter do

        let(:test_data) { {'foo' => 'bar', 'herp' => 'derp'} }

        it 'should implement << and deq' do
          @queue.should respond_to(:<<)
          @queue.should respond_to(:deq)
          @queue << test_data
          @queue.size.should == 1
          @queue.deq.should == test_data
          @queue.size.should == 0
        end

        it 'should implement empty?' do
          @queue.should respond_to(:empty?)

          @queue.empty?.should be_true

          @queue << test_data
          @queue.empty?.should be_false

          @queue.deq
          @queue.empty?.should be_true
        end

        it 'should implement size' do
          @queue.should respond_to(:size)

          @queue.size.should == 0

          @queue << test_data
          @queue.size.should == 1
        end

        it 'should implement num_waiting' do
          @queue.should respond_to(:num_waiting)

          @queue.num_waiting.should == 0

          3.times { Thread.new { @queue.deq } }

          [3,2,1,0].each do |n|
            sleep(0.2)
            @queue.num_waiting.should == n
            @queue << test_data
          end
        end

        it 'should implement clear' do
          @queue.should respond_to(:clear)

          @queue << test_data
          @queue.clear
          @queue.size.should == 0
        end

      end

      describe Basic do
        it_should_behave_like :an_adapter

        before(:each) { @queue = Queue.Basic }
        after(:all)   { @queue = nil }

      end

      describe Redis do
        it_should_behave_like :an_adapter

        before(:all) { @queue = Queue.Redis }
        after(:each) { @queue.clear }
        after(:all)  { @queue = nil }

      end

    end
  end
end