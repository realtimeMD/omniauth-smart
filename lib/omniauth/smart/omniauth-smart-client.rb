# frozen_string_literal: true

# OmniauthSmart Client attributes
# Required: issuer, client_id
# Optional but recommended: client_secret
# Optional org_id (the organization you wish to associate with this client), for multi-tenant apps
# Optional scope - this would override the default scope of the smart strategy
class OmniauthSmartClient
  attr_accessor :issuer, :client_id, :client_secret, :org_id, :scope

  def initialize(**args)
    @issuer = args[:issuer]
    @client_id = args[:client_id]
    @client_secret = args[:client_secret]
    @org_id = args[:org_id]
    @scope = args[:scope]
  end

  def is_confidential?
    !is_public?
  end

  def is_public?
    client_secret.nil?
  end
end
