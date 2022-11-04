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
    url = "http://example.com/#{rand(1..99)}"
    expect(OmniAuth::Smart::Conformance).to receive(:read_conformance).with(url).and_return("invalid: 'json'")
    expect{ OmniAuth::Smart::Conformance.get_conformance_from_server(url) }.to raise_error OmniAuth::Smart::ConformanceError
  end
end
