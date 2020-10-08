require 'spec_helper'
require 'rack/test'
require 'jwt'
require 'multi_json'
require 'sinatra'

A_CLIENT_ISSUER = "http://smart.org/123"
NOT_A_CLIENT_ISSUER = "notme"

CONFORMANCE = <<END_TEXT
{
  "resourceType": "Conformance",
  "rest": [{
      "security": {
        "service": [
          {
            "coding": [
              {
                "system": "http://hl7.org/fhir/restful-security-service",
                "code": "SMART-on-FHIR"
              }
            ],
            "text": "OAuth2 using SMART-on-FHIR profile (see http://docs.smarthealthit.org)"
          }
        ],
        "extension": [{
          "url": "http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris",
          "extension": [{
            "url": "token",
            "valueUri": "http://my-server.org/token"
          },{
            "url": "authorize",
            "valueUri": "http://my-server.org/authorize"
          },{
            "url": "manage",
            "valueUri": "http://my-server.org/authorizations/manage"
          }]
        }]
      }
  }]
}
END_TEXT

describe OmniAuth::Strategies::Smart do
  include Rack::Test::Methods
  def app
    Sinatra.new do
      configure do
        enable :sessions
      end
      use OmniAuth::Builder do
        provider :smart, backend: OmniAuth::Smart::BackendArray.new([OmniAuth::Smart::Client.new(issuer: A_CLIENT_ISSUER, client_id: "CLIENT_ID", client_secret: "CLIENT_SECRET", org_id: "ORG_ID")])
      end
      get "/auth/smart/callback" do
        MultiJson.encode(request.env["omniauth.auth"])
      end
    end
  end

  # note: these much match the parameters above (unfortunately let methods do not work within the context above)
  let(:client_id) {'CLIENT_ID'}
  let(:client_secret) {'CLIENT_SECRET'}
  let(:org_id) {'ORG_ID'}
  let(:open_id_configuration_url) { 'https://someurl.com' }
  let(:backend) { OmniAuth::Smart::BackendArray.new([OmniAuth::Smart::Client.new(issuer: A_CLIENT_ISSUER, client_id: client_id, client_secret: client_secret, org_id: org_id, open_id_configuration_url: open_id_configuration_url)]) }
  let(:application) do
    lambda do
      [200, {}, ['Hello.']]
    end
  end
  let(:smart) do
    OmniAuth::Strategies::Smart.new(application, backend: backend)
  end

  describe "options" do
    let(:subject) {smart.options}
    it 'has a backend' do
      expect(subject[:backend]).to_not be_nil
    end

    it 'has a default scope' do
      expect(subject[:default_scope]).to match /patient/i
    end

    it 'can override default scope' do
      smart_with_new_scope = OmniAuth::Strategies::Smart.new(application, default_scope: "NEW SCOPE")
      expect(smart_with_new_scope.options[:default_scope]).to eq "NEW SCOPE"
    end
  end

  describe "smart" do

    def stub_launch
      stub_request(:get, "#{A_CLIENT_ISSUER}/metadata").to_return(
          headers: {'Content-Type': 'application/json'},
          body: CONFORMANCE
      )
    end

    context "launch" do
      it 'errors if there is no issuer' do
        get '/auth/smart'
        expect(last_response.status).to eq(302)
        expect(last_response.location).to match /failure/
        expect(last_response.location).to match /Unknown issuer/i
      end

      it 'errors if the issuer is not in allowed_clients' do
        get "/auth/smart?iss=#{NOT_A_CLIENT_ISSUER}"
        expect(last_response.status).to eq(302)
        expect(last_response.location).to match /failure/
        expect(last_response.location).to match /Unknown issuer/i
      end

      it 'redirects to emr authentication server' do
        stub_launch
        get "/auth/smart?iss=#{URI.encode(A_CLIENT_ISSUER)}"
        expect(last_response.status).to eq(302)
        expect(last_response.location).to match /my-server.org\/authorize/
      end
    end

    let(:jwt_token) { { 'sub' => "SUBJECT", 'aud' => client_id, 'exp' => Time.now.to_i + 4*3600, 'iat' => Time.now.to_i } }
    let(:encoded_jwt_token) { JWT.encode(jwt_token,nil,'none') }

    def stub_authorization
      stub_request(:post, "http://my-server.org/token").to_return(
          headers: {'Content-Type': 'application/json'},
          body: <<END_TEXT
{
  "scope": "patient/*.read patient/Patient.read launch openid profile online_scope",
  "access_token": "ACCESS TOKEN",
  "patient": "PATIENT ID",
  "smart_style_url": "http://my-server.org/style.css",
  "id_token": "#{encoded_jwt_token}",
  "refresh_token": "refresh token"
}
END_TEXT
      )
    end

    context "callback" do
      it 'requests a token' do
        stub_launch
        stub_authorization
        get "/auth/smart?iss=#{URI.encode(A_CLIENT_ISSUER)}"
        expect(last_response.status).to eq(302)
        expect(last_response.location).to match /my-server.org\/authorize/

        if last_response.location =~ /state=([^&]*)/
          state_id = $1
        end
        expect(state_id).to_not be_nil
        expect_any_instance_of(OmniAuth::Smart::JwtVerification).to receive(:decode).and_return([jwt_token])
        get "/auth/smart/callback?code=1234&state=#{state_id}"
        expect(last_response.status).to be 200
        expect(last_response.body).to match /SUBJECT/
        expect(last_response.body).to match /ACCESS TOKEN/
      end

    end
  end

end
