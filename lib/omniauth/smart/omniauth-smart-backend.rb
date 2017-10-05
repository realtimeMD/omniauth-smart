# frozen_string_literal: true

# This backend lists the allowed clients that can be launched via the SMART launcher
# It is designed to allow this to be loaded from an appropriately formed ActiveRecord Model, or a yaml file

class OmniauthSmartBackend
  class AbstractMethodError < Exception; end;

  # Returns an OmniauthSmartClient if found, otherwise nil
  def find_by_issuer(issuer)
    raise AbstractMethodError.new("You need to implement find_by_issuer in your subclass")
  end
end

# A very simple backend that just keeps clients as an array of clients
class OmniauthSmartBackendArray < OmniauthSmartBackend
  def initialize(array_of_clients)
    @clients = array_of_clients
  end

  def find_by_issuer(issuer)
    @clients.find { |client| client.issuer == issuer }
  end
end
