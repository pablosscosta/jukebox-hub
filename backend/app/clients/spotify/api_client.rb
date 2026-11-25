module Spotify
  # Web API endpoints (api.spotify.com), always on behalf of a host.
  class ApiClient
    BASE_URL = "https://api.spotify.com/v1".freeze
    # Spotify answers at most 10 results per search page.
    SEARCH_LIMIT = 10

    def initialize(access_token:)
      @access_token = access_token
    end

    # Returns the profile hash: "id", "display_name", ...
    def me
      get("/me")
    end

    # Devices where Spotify is open right now. A device only shows up while the app is open
    # on it, so the list is often empty.
    # Docs: https://developer.spotify.com/documentation/web-api/reference/get-a-users-available-devices
    def devices
      get("/me/player/devices").fetch("devices", []).map { |attrs| Device.from_api(attrs) }
    end

    # Searches songs by name, artist or album. "market=from_token" limits the results to what can
    # be played in the host's country, and tracks Spotify marks as not playable are left out.
    # Docs: https://developer.spotify.com/documentation/web-api/reference/search
    def search_tracks(query, limit: SEARCH_LIMIT)
      items = get("/search", type: "track", q: query, limit:, market: "from_token").dig("tracks", "items") || []
      items.compact.reject { |attrs| attrs["is_playable"] == false }.map { |attrs| Track.from_api(attrs) }
    end

    # One track, or nil when it doesn't exist or can't be played in the host's country.
    # Docs: https://developer.spotify.com/documentation/web-api/reference/get-track
    def track(id)
      attrs = get("/tracks/#{ERB::Util.url_encode(id)}", market: "from_token")
      attrs["is_playable"] == false ? nil : Track.from_api(attrs)
    rescue Error => e
      raise unless [400, 404].include?(e.status)

      nil
    end

    # Starts a track on the party's device, replacing whatever was playing there.
    # Docs: https://developer.spotify.com/documentation/web-api/reference/start-a-users-playback
    def play(device_id:, track_id:)
      request("PUT", "/me/player/play", { device_id: }, json: { uris: ["spotify:track:#{track_id}"] })
    rescue Error => e
      raise DeviceNotFoundError.new("Device #{device_id} not found", status: e.status) if e.status == 404

      raise
    end

    # Docs: https://developer.spotify.com/documentation/web-api/reference/pause-a-users-playback
    def pause(device_id:)
      request("PUT", "/me/player/pause", { device_id: })
    end

    # What is playing now, or nil when Spotify isn't playing anywhere (it answers 204).
    # Docs: https://developer.spotify.com/documentation/web-api/reference/get-information-about-the-users-current-playback
    def playback
      body = request("GET", "/me/player")
      body.present? ? Playback.from_api(body) : nil
    end

    private

    def get(path, params = {})
      request("GET", path, params)
    end

    def request(method, path, params = {}, json: nil)
      url = "#{BASE_URL}#{path}"
      url += "?#{URI.encode_www_form(params)}" if params.any?
      status, body = Http.request(method, url, headers: { "Authorization" => "Bearer #{@access_token}" }, json:)
      raise Error.new("#{method} #{path} failed (#{status})", status:) unless status.between?(200, 299)

      body
    end
  end
end
