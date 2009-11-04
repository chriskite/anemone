require File.dirname(__FILE__) + '/spec_helper'

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

  end
end
