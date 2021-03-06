# encoding: utf-8
module RDStation
  class Authentication
    include HTTParty

    AUTH_TOKEN_URL = 'https://api.rd.services/auth/token'.freeze
    DEFAULT_HEADERS = { 'Content-Type' => 'application/json' }.freeze

    def initialize(client_id, client_secret)
      @client_id = client_id
      @client_secret = client_secret
    end

    #
    # param redirect_url
    #  URL that the user will be redirected
    #  after confirming application authorization
    #
    def auth_url(redirect_url)
      "https://api.rd.services/auth/dialog?client_id=#{@client_id}&redirect_url=#{redirect_url}"
    end

    # Public: Get the credentials from RD Station API
    #
    # code  - The code String sent by RDStation after the user confirms authorization.
    #
    # Examples
    #
    #   authenticate("123")
    #   # => { 'access_token' => '54321', 'expires_in' => 86_400, 'refresh_token' => 'refresh' }
    #
    # Returns the credentials Hash.
    # Raises RDStation::Error::ExpiredCodeGrant if the code has expired
    # Raises RDStation::Error::InvalidCredentials if the client_id, client_secret
    # or code is invalid.
    def authenticate(code)
      response = post_to_auth_endpoint(code: code)
      parsed_body = JSON.parse(response.body)
      return parsed_body unless parsed_body['errors']
      RDStation::ErrorHandler.new(response).raise_errors
    end

    #
    # param refresh_token
    #   parameter sent by RDStation after authenticate
    #
    def update_access_token(refresh_token)
      response = post_to_auth_endpoint(refresh_token: refresh_token)
      parsed_body = JSON.parse(response.body)
      return parsed_body unless parsed_body['errors']
      RDStation::ErrorHandler.new(response).raise_errors
    end

    private

    def post_to_auth_endpoint(params)
      default_body = { client_id: @client_id, client_secret: @client_secret }
      body = default_body.merge(params)

      self.class.post(
        AUTH_TOKEN_URL,
        body: body.to_json,
        headers: DEFAULT_HEADERS
      )
    end
  end
end
