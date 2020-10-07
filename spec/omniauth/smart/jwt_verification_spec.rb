require 'spec_helper'
require 'byebug'

describe OmniAuth::Smart::JwtVerification do
  let(:open_id_configuration_url) { 'https://openid.com' }
  let(:jwks_uri) { 'https://jwksuri.com' }

  let(:jwk) { JWT::JWK.new(OpenSSL::PKey::RSA.new(2048)) }
  let(:payload) { { data: 'data' } }
  let(:headers) { { kid: jwk.kid } }
  let(:token) { JWT.encode(payload, jwk.keypair, 'RS256', headers) }
  let(:other_jwk) { JWT::JWK.new(OpenSSL::PKey::RSA.new(2048)) }

  it 'is true' do
    stub_request(:get, open_id_configuration_url).to_return(
      body: { jwks_uri: jwks_uri }.to_json
    )
    stub_request(:get, jwks_uri).to_return(
      body: { keys: [jwk.export] }.to_json
    )
    expect(OmniAuth::Smart::JwtVerification.new(token, open_id_configuration_url).decode).to eq([{ 'data' => 'data' }, { 'kid' => jwk.kid, 'alg'=> 'RS256' }])
  end

  it 'is true' do
    stub_request(:get, open_id_configuration_url).to_return(
      body: { jwks_uri: jwks_uri }.to_json
    )
    stub_request(:get, jwks_uri).to_return(
      body: { keys: [other_jwk.export] }.to_json
    )
    expect { OmniAuth::Smart::JwtVerification.new(token, open_id_configuration_url).decode }.to raise_error(JWT::DecodeError)
  end
end
