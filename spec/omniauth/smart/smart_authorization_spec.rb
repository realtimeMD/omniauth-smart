require 'spec_helper'

RSpec.describe OmniAuth::Smart::Authorization do
  def stub_authorization
    stub_request(:post, "http://my-server.org/token").to_return(
        headers: {'Content-Type': 'application/json'},
        body: "{ \"some\": \"json\" }"
    )
  end

  it "can exchange a code for a token" do
    stub_authorization
    smart = OmniAuth::Smart::Authorization.new("http://my-server.org/token")
    result = smart.exchange_code_for_token(
             OmniAuth::Smart::Client.new(client_id: "CLIENT", client_secret: "SECRET"),
             "code",
             "http://my-server.org/redirect"
    )
    expect(result).to eq MultiJson.load("{ \"some\": \"json\" }")
  end
end