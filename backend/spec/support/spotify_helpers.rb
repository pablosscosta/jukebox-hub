# Fake Spotify app credentials for the test run. Real requests are blocked by WebMock, so
# every call to Spotify in a spec must be stubbed with the helpers below.
ENV.update(
  "SPOTIFY_CLIENT_ID" => "test-client-id",
  "SPOTIFY_CLIENT_SECRET" => "test-client-secret",
  "SPOTIFY_REDIRECT_URI" => "http://127.0.0.1:3000/auth/spotify/callback"
)

module SpotifyHelpers
  TOKEN_URL = "https://accounts.spotify.com/api/token".freeze
  ME_URL = "https://api.spotify.com/v1/me".freeze
  DEVICES_URL = "https://api.spotify.com/v1/me/player/devices".freeze

  def stub_spotify_token(body = default_token_body, status: 200)
    stub_request(:post, TOKEN_URL).to_return(status:, body: body.to_json, headers: json_headers)
  end

  def stub_spotify_me(body = { "id" => "spotify-user-1", "display_name" => "Pablo" }, status: 200)
    stub_request(:get, ME_URL).to_return(status:, body: body.to_json, headers: json_headers)
  end

  def stub_spotify_devices(devices = [spotify_device], status: 200)
    stub_request(:get, DEVICES_URL).to_return(status:, body: { "devices" => devices }.to_json, headers: json_headers)
  end

  # A device as the Spotify API describes it.
  def spotify_device(**overrides)
    { "id" => "device-1", "name" => "Notebook", "type" => "Computer", "is_active" => true,
      "is_restricted" => false, "is_private_session" => false, "volume_percent" => 50 }.merge(overrides.stringify_keys)
  end

  def default_token_body
    { "access_token" => "new-access-token", "refresh_token" => "new-refresh-token", "expires_in" => 3600 }
  end

  private

  def json_headers
    { "Content-Type" => "application/json" }
  end
end

RSpec.configure do |config|
  config.include SpotifyHelpers
end
