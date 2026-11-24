require "rails_helper"

RSpec.describe Spotify::AccountsClient do
  subject(:client) { described_class.new }

  describe "#authorize_url" do
    it "points to the Spotify consent page with PKCE and the scopes we need" do
      url = URI(client.authorize_url(state: "the-state", code_challenge: "the-challenge"))
      query = Rack::Utils.parse_query(url.query)

      expect(url.to_s).to start_with("https://accounts.spotify.com/authorize?")
      expect(query).to include(
        "response_type" => "code",
        "client_id" => "test-client-id",
        "redirect_uri" => "http://127.0.0.1:3000/auth/spotify/callback",
        "state" => "the-state",
        "code_challenge" => "the-challenge",
        "code_challenge_method" => "S256"
      )
      expect(query["scope"].split).to include("user-modify-playback-state", "user-read-playback-state")
    end
  end

  describe "#exchange_code" do
    it "sends the code and verifier with the app credentials" do
      stub_spotify_token

      tokens = client.exchange_code(code: "auth-code", code_verifier: "verifier")

      expect(tokens).to have_attributes(access_token: "new-access-token", refresh_token: "new-refresh-token")
      expect(a_request(:post, SpotifyHelpers::TOKEN_URL)
        .with(basic_auth: %w[test-client-id test-client-secret],
              body: hash_including("grant_type" => "authorization_code", "code" => "auth-code",
                                   "code_verifier" => "verifier"))).to have_been_made
    end

    it "computes when the access token expires" do
      stub_spotify_token

      freeze_time do
        expect(client.exchange_code(code: "c", code_verifier: "v").expires_at).to eq(1.hour.from_now)
      end
    end

    it "raises InvalidGrantError when Spotify refuses the code" do
      stub_spotify_token({ "error" => "invalid_grant" }, status: 400)

      expect { client.exchange_code(code: "used", code_verifier: "v") }.to raise_error(Spotify::InvalidGrantError)
    end

    it "raises Spotify::Error when the response has no refresh token" do
      stub_spotify_token({ "access_token" => "only-access", "expires_in" => 3600 })

      expect { client.exchange_code(code: "c", code_verifier: "v") }.to raise_error(Spotify::Error, /refresh token/)
    end

    it "raises Spotify::Error when Spotify fails" do
      stub_spotify_token({}, status: 503)

      expect { client.exchange_code(code: "c", code_verifier: "v") }.to raise_error(Spotify::Error, /503/)
    end

    it "raises Spotify::Error when Spotify can't be reached" do
      stub_request(:post, SpotifyHelpers::TOKEN_URL).to_timeout

      expect { client.exchange_code(code: "c", code_verifier: "v") }.to raise_error(Spotify::Error, /reach/)
    end
  end

  describe "#refresh" do
    it "returns nil as refresh token when Spotify keeps the old one" do
      stub_spotify_token({ "access_token" => "renewed", "expires_in" => 3600 })

      tokens = client.refresh(refresh_token: "old-refresh")

      expect(tokens).to have_attributes(access_token: "renewed", refresh_token: nil)
      expect(a_request(:post, SpotifyHelpers::TOKEN_URL)
        .with(body: hash_including("grant_type" => "refresh_token",
                                   "refresh_token" => "old-refresh"))).to have_been_made
    end
  end

  describe "configuration" do
    it "fails clearly when the Spotify env vars are missing" do
      original = ENV.delete("SPOTIFY_CLIENT_SECRET")

      expect { described_class.new }.to raise_error(Spotify::ConfigurationError, /SPOTIFY_CLIENT_SECRET/)
    ensure
      ENV["SPOTIFY_CLIENT_SECRET"] = original
    end
  end
end
