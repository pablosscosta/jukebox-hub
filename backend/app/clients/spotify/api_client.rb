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

    private

    def get(path)
      status, body = Http.request("GET", "#{BASE_URL}#{path}",
                                  headers: { "Authorization" => "Bearer #{@access_token}" })
      raise Error.new("GET #{path} failed (#{status})", status:) unless status == 200

      body
    end
  end
end
