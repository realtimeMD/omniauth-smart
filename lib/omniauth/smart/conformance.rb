require 'faraday'
require 'multi_json'

module OmniAuth
  module Smart

    class ConformanceError < StandardError; end;

    # Knows how to read the conformance statement from a SMART on FHIR server
    # When created it attempts to read the conformance statement from the service uri
    class Conformance
      attr_reader :authorize_url, :token_url

      # Read conformance from a server and returns a smart conformance object
      def self.get_conformance_from_server(service_uri)
        conformance_json = self.read_conformance(service_uri)
        OmniAuth::Smart::Conformance.new(conformance_json)
      end

      def initialize(conformance_json)
        raise ConformanceError.new("Expecting json hash, instead go #{conformance_json.class}") unless conformance_json.is_a?(Hash)
        @conformance_json = conformance_json
        parse
      end

      def self.read_conformance(service_uri)
        r = Faraday.get(conformance_uri_for_server(service_uri)) do |req|
          req.headers["Accept"] = "application/json"
        end
        MultiJson.load(r.body)
      end

      # parse the conformance_json
      # returns self
      def parse
        @authorize_url = nil
        @token_url = nil

        # the other values are stored in the security extension, so first parse this
        # and make sure it is a known security extension
        @security_extension = parse_security_extension
        raise ConformanceError.new("Unknown security extension: #{result}") unless is_known_security_extension?(@security_extension)

        @security_extension["extension"].each do |url_uri|
          if url_uri["url"]=="authorize"
            @authorize_url = url_uri["valueUri"]
          elsif url_uri["url"]=="token"
            @token_url = url_uri["valueUri"]
          end
        end

        # At this time it does not read the FHIR version
        # If your application is dependent on a particular FHIR version
        # you should check that the minimum version that you require is available
        # ["Conformance"]["FHIR"]["Version"]
        # example: "fhirVersion": "1.0.2"

        raise ConformanceError.new("No authorization uri") unless @authorize_url
        raise ConformanceError.new("No token uri") unless @token_url

        return self
      end

      def self.conformance_uri_for_server(server_uri)
        server_uri + "/metadata"
      end

      def is_known_security_extension?(security_extension_json)
        security_extension_json["url"] == "http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris"
      end

      def parse_security_extension
        if @conformance_json.has_key?("Conformance")
          @conformance_json["Conformance"]["rest"]["security"]["extension"]
        else
          @conformance_json["rest"][0]["security"]["extension"][0]
        end
      end
    end
  end
end

