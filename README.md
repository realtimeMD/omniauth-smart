# Omniauth::Smart

This is an [OmniAuth](https://github.com/omniauth/omniauth) strategy for authenticating using the [SMART on FHIR](https://smarthealthit.org) protocol.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-smart'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-smart

## Usage

## Register your application
 
SMART is designed to allow your application to be launched from within an electronic medical record. To properly ensure that your SMART application is working, you will need

 * an issuer URL: this is the URI of the site that will launch your application (for testing purposes you will be using a SMART sandbox)
 * client id : this will be a GUID that uniquely identifies your application
 * client secret : this will be a secret known only to your app and the SMART server. This is not always required (say for javascript in browser apps), but since this is a server version and can keep a secret, we recommend using it
 
You also need to specify an "org id" which will be a unique value passed back to your application that links this launch to an organization in your application (to support multi-tenant applications).

## SMART Sandboxes

* [SMART Sandbox](http://docs.smarthealthit.org/sandbox/)
* [Healthcare Services Platform Consortium](https://sandbox.hspconsortium.org/#/start)

[Cerner](code.cerner.com) and [Epic](open.epic.com) also offer test environments.

## Rails

Add this as a provider to config/initializers/omniauth.rb

Note: here we are using a simple array backend, but feel free to create your own backend. 

```ruby
require 'omniauth/smart/omniauth-smart-backend'
require 'omniauth/smart/omniauth-smart-client'

OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
      :smart,
      backend: OmniauthSmartBackendArray.new(
          [
              OmniauthSmartClient.new(
                  issuer: "ISSUER_URI",
                  client_id: ENV["CLIENT_ID"],
                  client_secret: ENV["CLIENT_SECRET"]
                  org_id: ENV["ORG_ID"])
          ]
      ),
      callback_url: "/auth/smart/callback"
  )
end
```

### Update your routes

OmniAuth will register rack routes /auth/smart and /auth/smart/callback

To get information about failures, you should register a failure method

```ruby
  get '/auth/failure'        => 'sessions#failure'
```

The OmniAuth /auth/smart/callback will initiate the request phase. Once it is done, it will then direct to your route for this, so you should also register a method for the callback.

```ruby
  get '/auth/smart/callback' => 'sessions#smart_callback'
```

### Handling the callback

In your sessions controller, require the OmniauthSmartHash so it is easier for you to parse the returned results. 

```ruby
require 'omniauth/smart/omniauth-smart-hash'
```

Then setup your callback method.


```ruby
  def smart_callback
    # 1. get provider identifier from omniauth
    smart = OmniauthSmartHash.new(request.env['omniauth.auth'])
    # do interesting things with the provider info, the patient context and the FHIR endpoint and token you just got!
  end
```

## FAQ

### What is the date time format for expiry dates in the token returned?

Expires at is a NumericDate "seconds since Epoch" http://self-issued.info/docs/draft-ietf-oauth-json-web-token.html#rfc.section.4.1.4

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/actmd/omniauth-smart.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

