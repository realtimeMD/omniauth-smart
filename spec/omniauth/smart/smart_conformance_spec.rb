require 'spec_helper'

RSpec.describe OmniAuth::Smart::Conformance do
  it "can parse a valid conformance json" do
    json = MultiJson.load(CONFORMANCE)
    expect{OmniAuth::Smart::Conformance.new(json)}.not_to raise_error
    smart = OmniAuth::Smart::Conformance.new(json)
    expect(smart.authorize_url).to eq "http://my-server.org/authorize"
    expect(smart.token_url).to eq "http://my-server.org/token"
  end

  it "raises an error when not valid" do
    expect{OmniAuth::Smart::Conformance.new("invalid: 'json'")}.to raise_error OmniAuth::Smart::ConformanceError
  end
end
