# frozen_string_literal: true

require "spec_helper"

RSpec.describe OmniAuth::Smart::BackendArray do
  it "can find a client" do
    backend = OmniAuth::Smart::BackendArray.new([
        OmniAuth::Smart::Client.new(issuer: "hello")
                                            ])
    expect(backend.find_by_issuer("hello")).to_not be_nil
    expect(backend.find_by_issuer("goodbye")).to be_nil
  end
end
