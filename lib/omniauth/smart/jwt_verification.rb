require 'jwt'

module OmniAuth
  module Smart
    class JwtVerification
      def initialize(token, open_id_configuration_url)
        @token = token
        @url = open_id_configuration_url
      end

      def decode
        conn = Faraday.new
        open_id_response = conn.get(@url)
        jwks_uri = MultiJson.load(open_id_response.body)['jwks_uri']
        jwk_response = conn.get(jwks_uri)
        jwks = MultiJson.load(jwk_response.body)
        JWT.decode(@token, nil, true, { algorithms: ['RS256'], jwks: transform_jwks_hash_to_symbols(jwks) })
      end

      private

      def transform_jwks_hash_to_symbols(jwks)
        { keys: jwks["keys"].map { |h| h.symbolize_keys } }
      end
    end
  end
end
