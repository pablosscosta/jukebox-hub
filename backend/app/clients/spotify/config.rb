module Spotify
  # Credentials of the app registered at https://developer.spotify.com/dashboard.
  Config = Data.define(:client_id, :client_secret, :redirect_uri) do
    def self.from_env
      env_vars = { client_id: "SPOTIFY_CLIENT_ID", client_secret: "SPOTIFY_CLIENT_SECRET",
                   redirect_uri: "SPOTIFY_REDIRECT_URI" }
      missing = env_vars.values.select { |name| ENV[name].blank? }
      raise ConfigurationError, "Missing env vars: #{missing.join(', ')}" if missing.any?

      new(**env_vars.transform_values { |name| ENV.fetch(name) })
    end
  end
end
