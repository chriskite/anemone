require 'spec_helper'

module Anemone
  describe HTTP do

    describe "fetch_page" do
      before(:each) do
        FakeWeb.clean_registry
      end

      it "should still return a Page if an exception occurs during the HTTP connection" do
        HTTP.stub!(:refresh_connection).and_raise(StandardError)
        http = Anemone::HTTP.new
        http.fetch_page(SPEC_DOMAIN).should be_an_instance_of(Page)
      end

      it "should set the nominated HTTP request headers" do
        net_http_get = double('Net::HTTP:Get')
        Net::HTTP::Get.stub(:new).and_return(net_http_get)
        net_http_get.should_receive(:add_field).with('Accept', 'text/html')
        http = Anemone::HTTP.new({ :http_request_headers => { 'Accept' => 'text/html' }})
        http.fetch_page(SPEC_DOMAIN)
      end
    end
  end
end
