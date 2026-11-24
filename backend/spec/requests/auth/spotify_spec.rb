require "rails_helper"

RSpec.describe "Spotify login" do
  let(:frontend_callback) { "http://127.0.0.1:5173/auth/callback" }

  # Starts the flow and returns the query Spotify received, like a browser would.
  def start_login
    get "/auth/spotify"
    Rack::Utils.parse_query(URI(response.location).query)
  end

  def redirect_query
    Rack::Utils.parse_query(URI(response.location).query)
  end

  describe "GET /auth/spotify" do
    it "redirects to the Spotify consent page with state and PKCE" do
      spotify_query = start_login

      expect(response).to have_http_status(:found)
      expect(response.location).to start_with("https://accounts.spotify.com/authorize")
      expect(spotify_query).to include("state" => be_present, "code_challenge_method" => "S256")
    end

    it "sends the host back to the frontend with an error when Spotify is not configured" do
      original = ENV.delete("SPOTIFY_CLIENT_ID")

      get "/auth/spotify"

      expect(response.location).to eq("#{frontend_callback}?error=spotify_not_configured")
    ensure
      ENV["SPOTIFY_CLIENT_ID"] = original
    end
  end

  describe "GET /auth/spotify/callback" do
    it "logs the host in and sends a one-time code to the frontend" do
      stub_spotify_token
      stub_spotify_me
      spotify_query = start_login

      get "/auth/spotify/callback", params: { code: "auth-code", state: spotify_query["state"] }

      expect(response.location).to start_with("#{frontend_callback}?code=")
      expect(HostToken.consume_login_code(redirect_query["code"]).spotify_user_id).to eq("spotify-user-1")
    end

    it "proves the PKCE verifier matches the challenge sent at the start" do
      stub_spotify_token
      stub_spotify_me
      spotify_query = start_login

      get "/auth/spotify/callback", params: { code: "auth-code", state: spotify_query["state"] }

      expect(a_request(:post, SpotifyHelpers::TOKEN_URL).with do |request|
        verifier = Rack::Utils.parse_query(request.body)["code_verifier"]
        Spotify::Pkce.challenge_for(verifier) == spotify_query["code_challenge"]
      end).to have_been_made
    end

    it "rejects a state that doesn't match the one in the cookie" do
      start_login

      get "/auth/spotify/callback", params: { code: "auth-code", state: "forged" }

      expect(response.location).to eq("#{frontend_callback}?error=invalid_state")
      expect(Host.count).to eq(0)
    end

    it "rejects a callback that didn't start in this browser" do
      get "/auth/spotify/callback", params: { code: "auth-code", state: "anything" }

      expect(response.location).to eq("#{frontend_callback}?error=invalid_state")
    end

    it "lets the frontend know when the host denied access" do
      start_login

      get "/auth/spotify/callback", params: { error: "access_denied" }

      expect(response.location).to eq("#{frontend_callback}?error=access_denied")
    end

    it "lets the frontend know when Spotify fails" do
      stub_spotify_token({ "error" => "invalid_grant" }, status: 400)
      spotify_query = start_login

      get "/auth/spotify/callback", params: { code: "auth-code", state: spotify_query["state"] }

      expect(response.location).to eq("#{frontend_callback}?error=login_failed")
    end

    it "only accepts the state once" do
      stub_spotify_token
      stub_spotify_me
      spotify_query = start_login
      get "/auth/spotify/callback", params: { code: "auth-code", state: spotify_query["state"] }

      get "/auth/spotify/callback", params: { code: "auth-code", state: spotify_query["state"] }

      expect(response.location).to eq("#{frontend_callback}?error=invalid_state")
    end
  end
end
