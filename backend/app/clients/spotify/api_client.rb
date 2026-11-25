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

    private

    def get(path, params = {})
      url = "#{BASE_URL}#{path}"
      url += "?#{URI.encode_www_form(params)}" if params.any?
      status, body = Http.request("GET", url,
                                  headers: { "Authorization" => "Bearer #{@access_token}" })
      raise Error.new("GET #{path} failed (#{status})", status:) unless status == 200

      body
    end
  end
end
