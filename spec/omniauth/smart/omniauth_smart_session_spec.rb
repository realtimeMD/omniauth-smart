require 'spec_helper'
require 'ostruct'

RSpec.describe OmniauthSmartSession do
  it "can launch" do
    fake_session = {}
    smart_session = OmniauthSmartSession.new(fake_session)
    conformance = OpenStruct.new({authorize_url: "authorize", token_url: "token"})
    client = OmniauthSmartClient.new(issuer: "hello/world")
    smart_session.launching(client, conformance, "yes/please")
    expect(smart_session.state_id).to_not be_nil
    expect(smart_session.status).to eq OmniauthSmartSession::STATUS_LAUNCHING
    expect(smart_session.authorize_url).to eq "authorize"
    expect(smart_session.token_url).to eq "token"
    expect(smart_session.issuer).to eq "hello/world"
    expect(smart_session.scope_requested).to eq "yes/please"

    expect(smart_session.is_launching?(smart_session.state_id)[:result]).to be true
    expect(smart_session.is_launching?(smart_session.generate_state_id)[:result]).to be false
    expect(smart_session.is_launching?(smart_session.generate_state_id)[:error]).to match /invalid state/i

    smart_session.launched
    expect(smart_session.is_launching?(smart_session.state_id)[:result]).to be false
    expect(smart_session.is_launching?(smart_session.state_id)[:error]).to match /invalid status/i
  end
end