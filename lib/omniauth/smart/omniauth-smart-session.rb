# frozen_string_literal: true

require "securerandom"

# This keeps track of the smart session information
class OmniauthSmartSession
  STATUS_LAUNCHING = "launching".freeze
  STATUS_LAUNCHED = "launched".freeze

  def initialize(session)
    @session = session
  end

  def issuer
    @session[:smart_issuer]
  end

  def issuer=(issuer)
    @session[:smart_issuer] = issuer
  end

  def state_id
    @session[:smart_state_id]
  end

  def state_id=(state_id)
    @session[:smart_state_id] = state_id
  end

  # generates a new random state id
  def generate_state_id
    SecureRandom.uuid
  end

  def status
    @session[:smart_status]
  end

  def status=(status)
    @session[:smart_status] = status
  end

  def authorize_url
    @session[:smart_authorize_url]
  end

  def authorize_url=(url)
    @session[:smart_authorize_url] = url
  end

  def token_url
    @session[:smart_token_url]
  end

  def token_url=(url)
    @session[:smart_token_url] = url
  end

  def scope_requested
    @session[:smart_scope_requested]
  end

  def scope_requested=(scope)
    @session[:smart_scope_requested] = scope
  end

  # events

  # Sets the session to track a new launch request
  def launching(client, conformance, scope_requested)
    self.state_id = generate_state_id
    self.status = STATUS_LAUNCHING
    self.authorize_url = conformance.authorize_url
    self.token_url = conformance.token_url
    self.issuer = client.issuer
    self.scope_requested = scope_requested
  end

  # returns a hash with { result: true or false, error: error message if false }
  # returns true iff is the correct state id, and status is LAUNCHING_STATUS
  def is_launching?(request_state)
    if request_state != state_id
      return { result: false, error: "An error occurred. Invalid state id" }
    end

    # is it in the correct state which MUST be launching
    if status != STATUS_LAUNCHING
      return { result: false, error: "An error occurred. Invalid status (#{status})" +
               "This can occur if you inadvertently refreshed the page. Try to launch it again" }
    end
    return { result: true, error: nil }
  end

  def launched
    self.status = STATUS_LAUNCHED
  end
end
