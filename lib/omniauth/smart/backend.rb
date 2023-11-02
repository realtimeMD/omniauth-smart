# This backend lists the allowed clients that can be launched via the SMART launcher
# By adding the find_by_issuer method to another backend definition (such as an active record class),
# you should be quickly able to use your secure storage system that stores allowed smart hosts

module OmniAuth
  module Smart
    class Backend
      class AbstractMethodError < Exception; end

      # Returns an OmniauthSmartClient if found, otherwise nil
      def find_by_issuer(issuer, params: nil)
        raise AbstractMethodError.new("You need to implement find_by_issuer in your subclass")
      end
    end

    # A very simple backend that just keeps clients as an array of clients
    class BackendArray < Backend

      def initialize(array_of_clients)
        @clients = array_of_clients
      end

      def find_by_issuer(issuer, ...)
        @clients.find {|client| client.issuer == issuer}
      end
    end
  end
end
