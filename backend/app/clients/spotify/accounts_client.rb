module Spotify
  # OAuth endpoints (accounts.spotify.com): consent page, code exchange and token refresh.
  # Docs: https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow
  class AccountsClient
    BASE_URL = "https://accounts.spotify.com".freeze
    SCOPES = %w[
      user-read-private
      user-read-playback-state
      user-modify-playback-state
      user-read-currently-playing
    ].freeze

    def initialize(config: Config.from_env)
      @config = config
    end

    def authorize_url(state:, code_challenge:)
      query = {
        response_type: "code",
        client_id: config.client_id,
        redirect_uri: config.redirect_uri,
        scope: SCOPES.join(" "),
        state:,
        code_challenge_method: "S256",
        code_challenge:
      }
      "#{BASE_URL}/authorize?#{query.to_query}"
    end

    def exchange_code(code:, code_verifier:)
      tokens = request_token(grant_type: "authorization_code", code:, redirect_uri: config.redirect_uri,
                             code_verifier:)
      raise Error, "Spotify did not send a refresh token" if tokens.refresh_token.blank?

      tokens
    end

    def refresh(refresh_token:)
      request_token(grant_type: "refresh_token", refresh_token:)
    end

    private

    attr_reader :config

    def request_token(form)
      status, body = Http.request("POST", "#{BASE_URL}/api/token", form:, headers: { "Authorization" => basic_auth })

      raise InvalidGrantError.new("Spotify refused the grant", status:) if body["error"] == "invalid_grant"
      raise Error.new("Token request failed (#{status}): #{body['error']}", status:) unless status == 200

      token_set(body)
    end

    # The app identifies itself with client_id:client_secret (HTTP Basic).
    def basic_auth
      "Basic #{Base64.strict_encode64("#{config.client_id}:#{config.client_secret}")}"
    end

    def token_set(body)
      TokenSet.new(
        access_token: body.fetch("access_token"),
        refresh_token: body["refresh_token"],
        expires_at: body.fetch("expires_in").to_i.seconds.from_now
      )
    end
  end
end
