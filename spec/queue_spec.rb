require 'spec_helper'

module Anemone
  describe Queue do

    it "should have a class method to produce a default queue" do
      Anemone::Queue.should respond_to(:Default)
      Anemone::Queue.Default.should be_an_instance_of(Default)
    end

    it "should have a class method to produce a Redis queue" do
      Anemone::Queue.should respond_to(:Redis)
      Anemone::Queue.Redis.should be_an_instance_of(Redis)
    end

  end

  module Queue

    shared_examples_for 'queue adapter' do

      it 'should implement <<' do
        pending
      end

      it 'should implement deq' do
        pending
      end

      it 'should implement empty?' do
        pending
      end

      it 'should implement size' do
        pending
      end

      it 'should implement num_waiting' do
        pending
      end

      it 'should implement clear' do
        pending
      end

    end

    describe Default do
      it_should_behave_like 'queue adapter'
    end

    describe Redis do
      it_should_behave_like 'queue adapter'
    end

  end
end