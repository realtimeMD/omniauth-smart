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
  let(:backend) { OmniAuth::Smart::BackendArray.new([OmniAuth::Smart::Client.new(issuer: A_CLIENT_ISSUER, client_id: client_id, client_secret: client_secret, org_id: org_id)]) }
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
      expect(subject[:default_scope]).to eq('patient/Patient.read user/Practitioner.read launch openid profile online_scope fhirUser')
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
        expect(last_response.location).to include 'failure'
        expect(last_response.location).to include 'Unknown+issuer'
      end

      it 'errors if the issuer is not in allowed_clients' do
        get "/auth/smart?iss=#{NOT_A_CLIENT_ISSUER}"
        expect(last_response.status).to eq(302)
        expect(last_response.location).to include 'failure'
        expect(last_response.location).to include 'Unknown+issuer'
      end

      it 'redirects to emr authentication server' do
        stub_launch
        get "/auth/smart?iss=#{CGI.escape(A_CLIENT_ISSUER)}"
        expect(last_response.status).to eq(302)
        expect(last_response.location).to match /my-server.org\/authorize/
      end
    end

    let(:id_token_exp) { Time.now.to_i + 4 * 3600 }
    let(:id_token) do
      { sub: "SUBJECT", aud: client_id, exp: id_token_exp, iat: Time.now.to_i }
    end
    let(:encoded_id_token) { JWT.encode(id_token, nil, 'none') }
    let(:ehr_domain) { nil }

    def stub_authorization
      stub_request(:post, "http://my-server.org/token").to_return(
          headers: {'Content-Type': 'application/json'},
          body: <<END_TEXT
{
  "scope": "patient/*.read patient/Patient.read launch openid profile online_scope",
  "access_token": "ACCESS TOKEN",
  "patient": "PATIENT ID",
  "smart_style_url": "http://my-server.org/style.css",
  "id_token": "#{encoded_id_token}",
  "refresh_token": "refresh token",
  "ehr_domain": "#{ehr_domain}"
}
END_TEXT
      )
    end

    describe "callback" do
      it 'requests a token' do
        stub_launch
        stub_authorization
        get "/auth/smart?iss=#{CGI.escape(A_CLIENT_ISSUER)}"
        expect(last_response.status).to eq(302)
        expect(last_response.location).to match /my-server.org\/authorize/

        if last_response.location =~ /state=([^&]*)/
          state_id = $1
        end
        expect(state_id).to_not be_nil

        get "/auth/smart/callback?code=1234&state=#{state_id}"
        expect(last_response.status).to be 200
        expect(last_response.body).to match /SUBJECT/
        expect(last_response.body).to match /ACCESS TOKEN/
      end

      context 'with an ehr_domain' do
        let(:ehr_domain) { 'example.com' }

        it 'sets ehr_domain' do
          stub_launch
          stub_authorization
          get "/auth/smart?iss=#{CGI.escape(A_CLIENT_ISSUER)}"
          if last_response.location =~ /state=([^&]*)/
            state_id = $1
          end
          expect(state_id).to_not be_nil

          get "/auth/smart/callback?code=1234&state=#{state_id}"
          parsed_body = JSON.parse(last_response.body)
          expect(parsed_body['extra']['ehr_domain']).to eq('example.com')
        end
      end

      context 'when cerner is the issuer' do
        let(:practitioner_id) { 'PRACTITIONER_ID' }
        let(:fhir_user) { "https://fhir-ehr-code.cerner.com/r4/product-id/Practitioner/#{practitioner_id}" }
        let(:id_token) do
          {
            sub: "SUBJECT",
            aud: client_id,
            exp: id_token_exp,
            iat: Time.now.to_i,
            fhirUser: fhir_user,
          }
        end

        it 'sets practitioner_id' do
          stub_launch
          stub_authorization
          get "/auth/smart?iss=#{CGI.escape(A_CLIENT_ISSUER)}"
          if last_response.location =~ /state=([^&]*)/
            state_id = $1
          end
          expect(state_id).to_not be_nil

          get "/auth/smart/callback?code=1234&state=#{state_id}"
          expect(last_response.status).to be 200
          expect(last_response.body).to match /SUBJECT/
          expect(last_response.body).to match /ACCESS TOKEN/

          parsed_body = JSON.parse(last_response.body)
          expect(parsed_body['extra']['practitioner_id']).to eq(practitioner_id)
          expect(parsed_body['extra']['fhir_user_uri']).to eq(fhir_user)
          expect(parsed_body['credentials']['id_token']).to eq(encoded_id_token)
        end
      end
    end
  end
end
