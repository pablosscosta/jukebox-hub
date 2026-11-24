module Spotify
  # Web API endpoints (api.spotify.com), always on behalf of a host.
  class ApiClient
    BASE_URL = "https://api.spotify.com/v1".freeze

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

    private

    def get(path)
      status, body = Http.request("GET", "#{BASE_URL}#{path}",
                                  headers: { "Authorization" => "Bearer #{@access_token}" })
      raise Error.new("GET #{path} failed (#{status})", status:) unless status == 200

      body
    end
  end
end
