$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module Anemone
  describe CookieStore do

    it "should start out empty if no cookies are specified" do
      CookieStore.new.empty?.should be true
    end

    it "should accept a Hash of cookies in the constructor" do
      CookieStore.new({'test' => 'cookie'})['test'].value.should == 'cookie'
    end

    it "should be able to merge an HTTP cookie string" do
      cs = CookieStore.new({'a' => 'a', 'b' => 'b'})
      cs.merge! "a=A; path=/, c=C; path=/"
      cs['a'].value.should == 'A'
      cs['b'].value.should == 'b'
      cs['c'].value.should == 'C'
    end

    it "should have a to_s method to turn the cookies into a string for the HTTP Cookie header" do
      CookieStore.new({'a' => 'a', 'b' => 'b'}).to_s.should == 'a=a;b=b'
    end

  end
end
