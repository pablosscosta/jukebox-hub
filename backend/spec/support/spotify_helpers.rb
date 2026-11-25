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
  SEARCH_URL = "https://api.spotify.com/v1/search".freeze
  TRACKS_URL = "https://api.spotify.com/v1/tracks".freeze
  PLAYER_URL = "https://api.spotify.com/v1/me/player".freeze
  PLAY_URL = "https://api.spotify.com/v1/me/player/play".freeze
  PAUSE_URL = "https://api.spotify.com/v1/me/player/pause".freeze
  # Spotify ids have 22 letters and digits; the jukebox checks the format.
  TRACK_ID = "4uLU6hMCjMI75M1A2tKUQC".freeze

  def stub_spotify_token(body = default_token_body, status: 200)
    stub_request(:post, TOKEN_URL).to_return(status:, body: body.to_json, headers: json_headers)
  end

  def stub_spotify_me(body = { "id" => "spotify-user-1", "display_name" => "Pablo", "product" => "premium" },
                      status: 200)
    stub_request(:get, ME_URL).to_return(status:, body: body.to_json, headers: json_headers)
  end

  def stub_spotify_devices(devices = [spotify_device], status: 200)
    stub_request(:get, DEVICES_URL).to_return(status:, body: { "devices" => devices }.to_json, headers: json_headers)
  end

  def stub_spotify_search(tracks = [spotify_track], status: 200)
    stub_request(:get, SEARCH_URL).with(query: hash_including({}))
                                  .to_return(status:, body: { "tracks" => { "items" => tracks } }.to_json,
                                             headers: json_headers)
  end

  def stub_spotify_track(track = spotify_track, status: 200)
    id = track&.fetch("id") || TRACK_ID
    body = status == 200 ? track : { "error" => { "status" => status, "message" => "Not found" } }
    stub_request(:get, "#{TRACKS_URL}/#{id}").with(query: hash_including({}))
                                             .to_return(status:, body: body.to_json, headers: json_headers)
  end

  def stub_spotify_play(status: 204)
    body = status == 204 ? "" : { "error" => { "status" => status, "message" => "Device not found" } }.to_json
    stub_request(:put, PLAY_URL).with(query: hash_including({})).to_return(status:, body:, headers: json_headers)
  end

  def stub_spotify_pause(status: 204)
    stub_request(:put, PAUSE_URL).with(query: hash_including({})).to_return(status:, body: "")
  end

  # What GET /me/player answers. Without a track, Spotify isn't playing anywhere (204, no body).
  def stub_spotify_playback(track_id: nil, playing: true, progress_ms: 0, duration_ms: 180_000)
    if track_id.nil?
      stub_request(:get, PLAYER_URL).to_return(status: 204, body: "")
    else
      body = { "is_playing" => playing, "progress_ms" => progress_ms,
               "item" => spotify_track(id: track_id, duration_ms:) }
      stub_request(:get, PLAYER_URL).to_return(status: 200, body: body.to_json, headers: json_headers)
    end
  end

  # A track as the Spotify API describes it (only the fields the jukebox reads, plus a few more).
  def spotify_track(**overrides)
    {
      "id" => TRACK_ID, "name" => "Garota de Ipanema", "duration_ms" => 323_000, "is_playable" => true,
      "explicit" => false, "artists" => [{ "id" => "artist-1", "name" => "Tom Jobim" }],
      "album" => { "name" => "Getz/Gilberto", "images" => [
        { "url" => "https://i.scdn.co/image/640", "width" => 640, "height" => 640 },
        { "url" => "https://i.scdn.co/image/300", "width" => 300, "height" => 300 },
        { "url" => "https://i.scdn.co/image/64", "width" => 64, "height" => 64 }
      ] }
    }.merge(overrides.stringify_keys)
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
