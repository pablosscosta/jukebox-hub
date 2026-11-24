module SpotifyAuth
  # Returns a Spotify access token that is still valid, renewing it with the refresh token
  # when needed. Every call to the Spotify API on behalf of a host should go through here.
  class FreshAccessToken
    def self.call(...) = new(...).call

    def initialize(host, accounts: Spotify::AccountsClient.new)
      @host = host
      @accounts = accounts
    end

    def call
      return @host.access_token unless @host.spotify_token_expired?

      # The row lock stops two requests from refreshing at the same time. The second one
      # waits, reloads and finds the token already renewed.
      @host.with_lock do
        refresh! if @host.spotify_token_expired?
      end
      @host.access_token
    rescue Spotify::InvalidGrantError
      # The host revoked access on Spotify: log them out so the frontend asks for a new login.
      @host.host_tokens.delete_all
      raise ReauthenticationRequired
    end

    private

    def refresh!
      tokens = @accounts.refresh(refresh_token: @host.refresh_token)
      @host.update!(
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token || @host.refresh_token,
        token_expires_at: tokens.expires_at
      )
    end
  end
end
