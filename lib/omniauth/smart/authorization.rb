require 'faraday'
require 'multi_json'

module OmniAuth
  module Smart
    # Knows how to communicate with the SMART authorization server
    # Note: we use faraday as this is the recommended library for Omniauth
    class Authorization

      def initialize(token_url)
        @token_url = token_url
      end

      def exchange_code_for_token(client, code, redirect_uri)
        data = {
            code: code,
            grant_type: 'authorization_code',
            redirect_uri: redirect_uri
        }
        if client.is_public?
          data["client_id"] = client.client_id
        end

        conn = Faraday.new do |conn|
          if client.is_confidential?
            conn.basic_auth(client.client_id, client.client_secret)
          end
          # this must be 'application/x-www-form-urlencoded'
          conn.request :url_encoded
          conn.adapter Faraday.default_adapter
        end

        r = conn.post(@token_url) do |req|
          req.headers["Accept"] = "application/json"
          req.body = URI.encode_www_form(data)
        end

        MultiJson.load(r.body)
      end
    end
  end
end
