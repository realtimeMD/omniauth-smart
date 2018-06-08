# This manages all of the smart information that is persisted in the session hash from the omniauth strategy
# Example:
# #<OmniAuth::AuthHash
#   credentials=#<OmniAuth::AuthHash
#     expires=true
#     expires_at=1494967227
#     token="JWT_TOKEN_HERE"
#   >
#   extra=#<OmniAuth::AuthHash
#     fhir_uri="https://fhir-ehr.emr.com/dstu2/TENANT_GUID"
#     org_id=2
#     patient_id="PATIENT_ID"
#     scope_granted="patient/Patient.read launch openid profile"
#     style_url="https://smart.emr.com/styles/smart-v1.json"
#   >
#   info=#<OmniAuth::AuthHash::InfoHash>
#   provider="smart"
#   uid="emr_username"
# >

module OmniAuth
  module Smart
    class Hash
      attr_reader :omniauth_hash

      def initialize(omniauth_hash)
        @omniauth_hash = omniauth_hash
      end

      def uid
        @omniauth_hash[:uid]
      end

      def scope_granted
        extra['scope_granted']
      end

      def style_url
        extra['style_url']
      end

      def org_id
        extra['org_id']
      end

      def patient_id
        extra['patient_id']
      end

      def fhir_uri
        extra['fhir_uri']
      end

      def token
        raise KeyError.new("Missing token in omniauth.auth.credentials") unless credentials.has_key?("token")
        credentials['token']
      end

      def expires
        credentials['expires']
      end

      # this returns a unix timestamp
      # to convert to DateTime use Time.at(expires_at)
      def expires_at
        credentials['expires_at']
      end

      def extra
        raise KeyError.new("Missing extra section in omniauth key from hash") unless @omniauth_hash.has_key?("extra")
        @omniauth_hash["extra"]
      end

      def credentials
        raise KeyError.new("Missing credentials section in omniauth key from hash") unless @omniauth_hash.has_key?("credentials")
        @omniauth_hash["credentials"]
      end
    end
  end
end

