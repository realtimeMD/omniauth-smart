require 'omniauth'
require 'jwt'
require 'omniauth/smart/backend'
require 'omniauth/smart/client'
require 'omniauth/smart/session'
require 'omniauth/smart/conformance'
require 'omniauth/smart/authorization'

module OmniAuth
  module Strategies

    # Smart strategy for launching and processing SMART launches from https://smarthealthit.org
    #
    # When the EMR launches direct it to /auth/smart
    # This will check conformance, and then build the appropriate url to redirect back to the EMR for authorization
    #
    # After authorization, the browser will be redirected to the callback path (specified in options,
    # usually /auth/smart/callback). In the callback, it will change the code for an Authorization bearer token, and
    # get the additional launch parameters including the patient_id
    #
    # Options:
    # backend: this is the OmniauthSmartBackend that identifies all the allowed clients
    # default_scope: this is the default scope for clients, if scope is defined in the client definition then that scope has precedence
    #
    # On successful callback, the omniauth hash will include the following elements:
    #   uid = provider id we get after exchange the id token (in Cerner this is their user name)
    #
    # credentials:
    #   token: STRING  # access token that you will need if you are going to make FHIR queries
    #   expires: true  # always expire, set by EMR policy
    #   expires_at: INTEGER  # second count when it expires (i.e. unix epoch time)
    #
    # extra:
    #   org_id: GUID  # the org id associated with the client this was called from (see allowed_clients hash)
    #   patient_id: STRING  # fhir identifier for this patient, to get demographics you would need to query FHIR uri
    #   fhir_uri: URI # the uri of the FHIR server
    #   style_url: URI # OPTIONAL, might be returned by the emr if they have some suggested styles
    #   scope_granted: STRING # the scopes that were actually granted (note: might be different than those requested)
    #
    class Smart
      include OmniAuth::Strategy

      option :backend, nil
      option :default_scope, "patient/Patient.read user/Practitioner.read launch openid profile online_scope fhirUser"

      def request_phase
        return unless has_backend?

        issuer = request.params["iss"]
        if issuer.nil?
          log :error, "No issuer specified"
          fail! "Unknown issuer. Is your organization configured correctly?"
        else
          client = options[:backend].find_by_issuer(issuer)
          if client
              redirect smart_url_for(client)
          else
            log :error, "Unknown issuer #{issuer}"
            fail! "Unknown issuer."
          end
        end
      end

      def callback_phase
        return unless no_callback_errors?
        return unless state_is_correct?

        @issuer = smart_session.issuer
        unless @issuer
          fail! "No smart client"
          return
        end

        @client = options[:backend].find_by_issuer(@issuer)
        unless @client
          fail! "No backend configured for #{@issuer}"
          return
        end

        code = request.params["code"]
        token_response_json = OmniAuth::Smart::Authorization.new(smart_session.token_url).exchange_code_for_token(@client, code, redirect_uri)

        if token_response_json["error"]
          fail! "An error occurred. Could not get token."
        end

        @smart_scope_granted = token_response_json["scope"]
        if @smart_scope_granted != options[:scope]
          log :warn, "Different scope granted: requested=#{options[:scope]} granted=#{@smart_scope_granted}"
        end

        @smart_access_token = token_response_json["access_token"]
        @smart_patient_id = token_response_json["patient"]
        @smart_style_url = token_response_json["smart_style_url"]
        @smart_service_uri = @client.issuer

        # the id_token is a JWT with the parameters specific in the SMART spec
        # id_data data is in the first item, (the second item should contain the JWT algorithm)
        # See http://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation
        # Also http://fhir.cerner.com/authorization/openid-connect/
        # Since we have communicated directly with the token server to obtain this token, we will consider this a trusted token and only confirm the audience to be our client_id
        @id_token = token_response_json["id_token"]
        @id_data = JWT.decode(@id_token, nil, false, aud: @client.client_id, verify_aud: true)[0]

        # including @fhir_user_uri for future debugging in case the shape changes
        @fhir_user_uri = @id_data['fhirUser']
        @practitioner_id = @fhir_user_uri&.split('/')&.last

        # the refresh token may or may not be included in the json
        @refresh_token = token_response_json["refresh_token"]

        super
      end

      uid do
        @id_data['sub']
      end

      credentials do
        {
            :token => @smart_access_token,
            :id_token => @id_token,
            :expires => true,
            :expires_at => @id_data["iat"]
        }
      end

      extra do
        {
            org_id: @client.org_id,
            patient_id: @smart_patient_id,
            practitioner_id: @practitioner_id,
            fhir_user_uri: @fhir_user_uri,
            fhir_uri: @smart_service_uri,
            style_url: @smart_style_url,
            scope_granted: @smart_scope_granted,
            refresh_token: @refresh_token
        }
      end

      private

      def smart_session
        @smart_session = @smart_session || OmniAuth::Smart::Session.new(session)
      end

      def has_backend?
        fail! "No backend defined!" unless options[:backend]
        options[:backend]
      end

      def smart_url_for(client)
        # Please note here we use our whitelisted client.issuer to
        # get the conformance statement
        conformance = OmniAuth::Smart::Conformance::get_conformance_from_server(client.issuer)
        scope_requested = client.scope || options[:default_scope]
        smart_session.launching(client, conformance, scope_requested)
        url_with_encoded_params(conformance.authorize_url, {
            response_type: "code",
            client_id: client.client_id,
            scope: scope_requested,
            redirect_uri: redirect_uri,
            aud: client.issuer,
            launch: launch_context_id,
            state: smart_session.state_id
        })
      end

      def launch_context_id
        request.params["launch"].to_s
      end

      # SMART protocol requires submitting the url with encoded parameters
      def url_with_encoded_params(uri, params)
        # uri parsing https://gitlab.com/honeyryderchuck/httpx/-/blob/master/lib/httpx/utils.rb#L28-41
        "#{URI::RFC2396_Parser.new.escape(uri)}?#{URI.encode_www_form(params)}"
      end

      def redirect_uri
        full_host + script_name + callback_path
      end

      def no_callback_errors?
        if request.params["error"]
          log :error, "Error from smart server: #{request.params['error_description']}"
          fail! "An error occurred: #{request.params['error_description']}"
          return false
        end
        return true
      end

      def state_is_correct?
        result = smart_session.is_launching?(request.params["state"])
        if result[:result]
          smart_session.launched
          return true
        else
          fail! result[:error]
          return false
        end
      end
    end
  end
end
