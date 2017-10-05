# frozen_string_literal: true

require "spec_helper"

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

RSpec.describe SmartConformance do
  it "can parse a valid conformance json" do
    json = MultiJson.load(CONFORMANCE)
    expect { SmartConformance.new(json) }.not_to raise_error
    smart = SmartConformance.new(json)
    expect(smart.authorize_url).to eq "http://my-server.org/authorize"
    expect(smart.token_url).to eq "http://my-server.org/token"
  end

  it "raises an error when not valid" do
    expect { SmartConformance.new("invalid: 'json'") }.to raise_error SmartConformanceError
  end
end
