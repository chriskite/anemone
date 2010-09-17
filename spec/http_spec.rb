require File.dirname(__FILE__) + '/spec_helper'

module Anemone
  describe HTTP do

    describe "fetch_page" do
      before(:each) do
        FakeWeb.clean_registry
      end

      it "should still return a Page if an exception occurs during the HTTP connection" do
        http = HTTP.new
        http.should_receive(:refresh_connection).once.and_raise(RuntimeError)
        http.fetch_page(SPEC_DOMAIN).should be_an_instance_of(Page)
      end

    end
  end
end
