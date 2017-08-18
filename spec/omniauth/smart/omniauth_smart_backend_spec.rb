require 'spec_helper'

RSpec.describe OmniauthSmartBackendArray do
  it "can find a client" do
    backend = OmniauthSmartBackendArray.new([
        OmniauthSmartClient.new(issuer: "hello")
                                            ])
    expect(backend.find_by_issuer("hello")).to_not be_nil
    expect(backend.find_by_issuer("goodbye")).to be_nil
  end
end