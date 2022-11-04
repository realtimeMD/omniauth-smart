require 'rubygems'
require 'bundler'
Bundler.setup :default, :development, :test

require 'webmock/rspec'
require 'omniauth/smart'
require 'omniauth/smart/backend'
require 'omniauth/smart/session'
require 'omniauth/smart/client'
require 'omniauth/smart/conformance'
require 'omniauth/smart/authorization'

WebMock.disable_net_connect!

RSpec.configure do |config|
end

# Turn off all the OmniAuth logging messages
# This can be helpful for debugging, in which case just comment out this line
OmniAuth.config.logger = Logger.new('/dev/null')

# Override OmniAuth 2.0 default to only support POST requests since the smart workflow uses GET
OmniAuth.config.allowed_request_methods = [:get, :post]
