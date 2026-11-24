module SpotifyAuth
  # Last step of the OAuth flow: trades the authorization code for Spotify tokens, saves the
  # host and returns a one-time login code for the frontend.
  class CompleteLogin
    def self.call(...) = new(...).call

    def initialize(code:, code_verifier:, accounts: Spotify::AccountsClient.new)
      @code = code
      @code_verifier = code_verifier
      @accounts = accounts
    end

    def call
      tokens = @accounts.exchange_code(code: @code, code_verifier: @code_verifier)
      profile = Spotify::ApiClient.new(access_token: tokens.access_token).me

      Host.transaction do
        host = save_host(profile, tokens)
        HostToken.issue!(host:, kind: :login_code)
      end
    end

    private

    def save_host(profile, tokens)
      host = Host.find_or_initialize_by(spotify_user_id: profile.fetch("id"))
      host.update!(
        display_name: profile["display_name"].presence || profile.fetch("id"),
        product: profile["product"],
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        token_expires_at: tokens.expires_at
      )
      host
    end
  end
end
