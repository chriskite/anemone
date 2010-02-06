require File.dirname(__FILE__) + '/spec_helper'

module Anemone
  describe CookieStore do

    it "should start out empty if no cookies are specified" do
      CookieStore.new.empty?.should be true
    end

  end
end
